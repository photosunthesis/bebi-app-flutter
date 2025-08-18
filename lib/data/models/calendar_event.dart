import 'dart:ui';

import 'package:bebi_app/constants/hive_type_ids.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'calendar_event.g.dart';

@HiveType(typeId: HiveTypeIds.calendarEvent)
class CalendarEvent extends Equatable {
  CalendarEvent({
    required this.id,
    this.recurringEventId,
    required this.title,
    this.notes,
    required DateTime date,
    required DateTime startTime,
    DateTime? endTime,
    this.allDay = false,
    required this.repeatRule,
    required this.eventColor,
    required this.users,
    required this.createdBy,
    required this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : _date = date.toUtc(),
       _startTime = startTime.toUtc(),
       _endTime = endTime?.toUtc(),
       _createdAt = (createdAt ?? DateTime.now()).toUtc(),
       _updatedAt = (updatedAt ?? DateTime.now()).toUtc();

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] as String,
      notes: data['notes'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      startTime: (data['start_time'] as Timestamp).toDate(),
      endTime: data['end_time'] != null
          ? (data['end_time'] as Timestamp).toDate()
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

  @HiveField(0)
  final String id;
  final String? recurringEventId; // Used in UI only, not stored in Firestore
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String? notes;
  @HiveField(3)
  final DateTime _date;
  @HiveField(4)
  final DateTime _startTime;
  @HiveField(5)
  final DateTime? _endTime;
  @HiveField(6)
  final bool allDay;
  @HiveField(7)
  final RepeatRule repeatRule;
  @HiveField(8)
  final EventColor eventColor;
  @HiveField(9)
  final List<String> users;
  @HiveField(10)
  final String createdBy;
  @HiveField(11)
  final String updatedBy;
  @HiveField(12)
  final DateTime _createdAt;
  @HiveField(13)
  final DateTime _updatedAt;

  DateTime get date => _date.toLocal();
  DateTime get startTime => _startTime.toLocal();
  DateTime? get endTime => _endTime?.toLocal();
  DateTime get createdAt => _createdAt.toLocal();
  DateTime get updatedAt => _updatedAt.toLocal();
  Color get color => eventColor.color;
  bool get isRecurring => repeatRule.frequency != RepeatFrequency.doNotRepeat;
  bool get isLastRecurringEvent =>
      isRecurring &&
      ((repeatRule.endDate != null &&
              date.isAtSameMomentAs(repeatRule.endDate!)) ||
          (repeatRule.occurrences != null &&
              recurringEventId != null &&
              int.parse(recurringEventId!.split('_').last) >=
                  repeatRule.occurrences! - 1));

  CalendarEvent copyWith({
    String? id,
    String? recurringEventId,
    String? title,
    String? notes,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
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
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      repeatRule: repeatRule ?? this.repeatRule,
      eventColor: eventColor ?? this.eventColor,
      users: users ?? this.users,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'notes': notes,
      'date': Timestamp.fromDate(date),
      'start_time': Timestamp.fromDate(startTime),
      'end_time': endTime != null ? Timestamp.fromDate(endTime!) : null,
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
    date,
    startTime,
    endTime,
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
