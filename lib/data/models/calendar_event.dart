import 'dart:ui';

import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType { reminder, menstruation, ovulation }

enum EventColor {
  green,
  blue,
  yellow,
  red,
  purple,
  orange;

  Color get color => switch (this) {
    EventColor.green => AppColors.green,
    EventColor.blue => AppColors.blue,
    EventColor.yellow => AppColors.yellow,
    EventColor.red => AppColors.red,
    EventColor.purple => AppColors.purple,
    EventColor.orange => AppColors.orange,
  };
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    this.notes,
    required this.eventType,
    required DateTime startDate,
    DateTime? endDate,
    this.allDay = false,
    required this.repeatRule,
    this.location,
    required this.eventColor,
    required this.users,
    required this.createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : _startDate = startDate,
       _endDate = endDate,
       _createdAt = createdAt,
       _updatedAt = updatedAt,
       assert(
         allDay || endDate != null,
         'End date must be provided if event is not all-day',
       );

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] as String,
      notes: data['notes'] as String?,
      eventType: EventType.values.firstWhere(
        (e) => e.name == data['event_type'],
      ),
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: data['end_date'] != null
          ? (data['end_date'] as Timestamp).toDate()
          : null,
      allDay: data['all_day'] as bool? ?? false,
      repeatRule: RepeatRule.fromMap(
        data['repeat_rule'] as Map<String, dynamic>,
      ),
      location: data['location'] as String?,
      eventColor: EventColor.values.firstWhere(
        (e) => e.name == data['event_color'],
      ),
      users: data['users'] as List<String>,
      createdBy: data['created_by'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  final String id;
  final String title;
  final String? notes;
  final EventType eventType;
  final DateTime _startDate;
  final DateTime? _endDate;
  final bool allDay;
  final RepeatRule repeatRule;
  final String? location;
  final EventColor eventColor;
  final List<String> users;
  final String createdBy;
  final DateTime _createdAt;
  final DateTime _updatedAt;

  DateTime get startDate => _startDate.toLocal();
  DateTime? get endDate => _endDate?.toLocal();
  DateTime get createdAt => _createdAt.toLocal();
  DateTime get updatedAt => _updatedAt.toLocal();

  Color get color => eventColor.color;

  Map<String, dynamic> toFirestore() {
    return {
      // ID is handled by Firestore
      'title': title,
      'notes': notes,
      'event_type': eventType.name,
      'start_date': Timestamp.fromDate(_startDate),
      'end_date': _endDate != null ? Timestamp.fromDate(_endDate) : null,
      'all_day': allDay,
      'repeat_rule': repeatRule.toMap(),
      'location': location,
      'event_color': eventColor.name,
      'users': users,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(_createdAt),
      'updated_at': Timestamp.fromDate(_updatedAt),
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? notes,
    EventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    bool? allDay,
    RepeatRule? repeatRule,
    String? location,
    EventColor? eventColor,
    List<String>? users,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      eventType: eventType ?? this.eventType,
      startDate: startDate ?? _startDate,
      endDate: endDate ?? _endDate,
      allDay: allDay ?? this.allDay,
      repeatRule: repeatRule ?? this.repeatRule,
      location: location ?? this.location,
      eventColor: eventColor ?? this.eventColor,
      users: users ?? this.users,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? _createdAt,
      updatedAt: updatedAt ?? _updatedAt,
    );
  }
}
