import 'dart:ui';

import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CalendarEvent extends Equatable {
  CalendarEvent({
    required this.id,
    this.recurringEventId,
    required this.title,
    this.notes,
    required DateTime startDate,
    DateTime? endDate,
    this.allDay = false,
    required this.repeatRule,
    required this.eventColor,
    required this.users,
    required this.createdBy,
    required this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : _startDate = startDate.toUtc(),
       _endDate = endDate?.toUtc(),
       _createdAt = (createdAt ?? DateTime.now()).toUtc(),
       _updatedAt = (updatedAt ?? DateTime.now()).toUtc();

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] as String,
      notes: data['notes'] as String?,
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: data['end_date'] != null
          ? (data['end_date'] as Timestamp).toDate()
          : null,
      allDay: data['all_day'] as bool? ?? false,
      repeatRule: RepeatRule.fromMap(
        data['repeat_rule'] as Map<String, dynamic>,
      ),
      eventColor: EventColor.values.firstWhere(
        (e) => e.name == data['event_color'],
      ),
      createdBy: data['created_by'] as String,
      updatedBy: data['updated_by'] as String,
      users: List<String>.from(data['users'] as List<dynamic>),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  final String id;
  final String? recurringEventId; // Used in UI only, not stored in Firestore
  final String title;
  final String? notes;
  final DateTime _startDate;
  final DateTime? _endDate;
  final bool allDay;
  final RepeatRule repeatRule;
  final EventColor eventColor;
  final List<String> users;
  final String createdBy;
  final String updatedBy;
  final DateTime _createdAt;
  final DateTime _updatedAt;

  DateTime get startDate => _startDate.toLocal();
  DateTime? get endDate => _endDate?.toLocal();
  DateTime get createdAt => _createdAt.toLocal();
  DateTime get updatedAt => _updatedAt.toLocal();
  Color get color => eventColor.color;
  bool get isRecurring => repeatRule.frequency != RepeatFrequency.doNotRepeat;
  bool get isLastRecurringEvent =>
      isRecurring &&
      ((_endDate != null && _startDate.isAtSameMomentAs(_endDate)) ||
          (repeatRule.occurrences != null &&
              recurringEventId != null &&
              int.parse(recurringEventId!.split('_').last) >=
                  repeatRule.occurrences! - 1));

  CalendarEvent copyWith({
    String? id,
    String? recurringEventId,
    String? title,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    bool? allDay,
    RepeatRule? repeatRule,
    EventColor? eventColor,
    List<String>? users,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      recurringEventId: recurringEventId ?? this.recurringEventId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      startDate: startDate?.toUtc() ?? this.startDate,
      endDate: endDate?.toUtc() ?? this.endDate,
      allDay: allDay ?? this.allDay,
      repeatRule: repeatRule ?? this.repeatRule,
      eventColor: eventColor ?? this.eventColor,
      users: users ?? this.users,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt?.toUtc() ?? this.createdAt,
      updatedAt: updatedAt?.toUtc() ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'notes': notes,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'all_day': allDay,
      'repeat_rule': repeatRule.toMap(),
      'event_color': eventColor.name,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'users': users,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
    id,
    recurringEventId,
    title,
    notes,
    startDate,
    endDate,
    allDay,
    repeatRule,
    eventColor,
    users,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];
}

enum EventColor with LocalizationsMixin {
  black,
  green,
  blue,
  yellow,
  pink,
  orange,
  red;

  Color get color => switch (this) {
    EventColor.black => AppColors.stone600,
    EventColor.green => AppColors.green,
    EventColor.blue => AppColors.blue,
    EventColor.yellow => AppColors.yellow,
    EventColor.pink => AppColors.pink,
    EventColor.orange => AppColors.orange,
    EventColor.red => AppColors.red,
  };

  String get label => switch (this) {
    EventColor.black => l10n.eventColorBlack,
    EventColor.green => l10n.eventColorGreen,
    EventColor.blue => l10n.eventColorBlue,
    EventColor.yellow => l10n.eventColorYellow,
    EventColor.pink => l10n.eventColorPink,
    EventColor.orange => l10n.eventColorOrange,
    EventColor.red => l10n.eventColorRed,
  };
}
