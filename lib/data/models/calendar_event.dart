import 'dart:ui';

import 'package:bebi_app/data/models/cycle_event.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    this.notes,
    this.isCycleEvent = false,
    required DateTime date,
    required DateTime startTime,
    DateTime? endTime,
    this.allDay = false,
    required this.repeatRule,
    this.location,
    required this.eventColor,
    required this.createdBy,
    required this.users,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : _date = date,
       _startTime = startTime,
       _endTime = endTime,
       _createdAt = createdAt,
       _updatedAt = updatedAt;

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] as String,
      notes: data['notes'] as String?,
      isCycleEvent: data['is_cycle_event'] as bool? ?? false,
      date: (data['date'] as Timestamp).toDate(),
      startTime: (data['start_time'] as Timestamp).toDate(),
      endTime: data['end_time'] != null
          ? (data['end_time'] as Timestamp).toDate()
          : null,
      allDay: data['all_day'] as bool? ?? false,
      repeatRule: RepeatRule.fromMap(
        data['repeat_rule'] as Map<String, dynamic>,
      ),
      location: data['location'] as String?,
      eventColor: EventColors.values.firstWhere(
        (e) => e.name == data['event_color'],
      ),
      createdBy: data['created_by'] as String,
      users: List<String>.from(data['users'] as List<dynamic>),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  final String id;
  final String title;
  final String? notes;
  final bool isCycleEvent;
  final DateTime _date;
  final DateTime _startTime;
  final DateTime? _endTime;
  final bool allDay;
  final RepeatRule repeatRule;
  final String? location;
  final EventColors eventColor;
  final String createdBy;
  final List<String> users;
  final DateTime _createdAt;
  final DateTime _updatedAt;

  DateTime get date => _date.toLocal();
  DateTime get startTime => _startTime.toLocal();
  DateTime? get endTime => _endTime?.toLocal();
  DateTime get createdAt => _createdAt.toLocal();
  DateTime get updatedAt => _updatedAt.toLocal();

  Color get color => eventColor.color;

  Map<String, dynamic> toFirestore() {
    return {
      // ID is handled by Firestore
      'title': title,
      'notes': notes,
      'is_cycle_event': isCycleEvent,
      'date': Timestamp.fromDate(_date),
      'start_time': Timestamp.fromDate(_startTime),
      'end_time': _endTime != null ? Timestamp.fromDate(_endTime) : null,
      'all_day': allDay,
      'repeat_rule': repeatRule.toMap(),
      'location': location,
      'event_color': eventColor.name,
      'created_by': createdBy,
      'users': users,
      'created_at': Timestamp.fromDate(_createdAt),
      'updated_at': Timestamp.fromDate(_updatedAt),
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? notes,
    bool? isCycleEvent,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    RepeatRule? repeatRule,
    String? location,
    EventColors? eventColor,
    String? createdBy,
    List<String>? users,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      isCycleEvent: isCycleEvent ?? this.isCycleEvent,
      date: date ?? _date,
      startTime: startTime ?? _startTime,
      endTime: endTime ?? _endTime,
      allDay: allDay ?? this.allDay,
      repeatRule: repeatRule ?? this.repeatRule,
      location: location ?? this.location,
      eventColor: eventColor ?? this.eventColor,
      createdBy: createdBy ?? this.createdBy,
      users: users ?? this.users,
      createdAt: createdAt ?? _createdAt,
      updatedAt: updatedAt ?? _updatedAt,
    );
  }

  CycleEvent toCycleEvent() {
    // TODO Add more robust checks
    assert(isCycleEvent, 'Event is not a cycle event.');
    return this as CycleEvent;
  }
}
