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
    required DateTime startDate,
    DateTime? endDate,
    this.allDay = false,
    required this.repeatRule,
    this.location,
    required this.eventColor,
    required this.createdBy,
    this.partnershipId,
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
      isCycleEvent: data['is_cycle_event'] as bool? ?? false,
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: data['end_date'] != null
          ? (data['end_date'] as Timestamp).toDate()
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
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  final String id;
  final String title;
  final String? notes;
  final bool isCycleEvent;
  final DateTime _startDate;
  final DateTime? _endDate;
  final bool allDay;
  final RepeatRule repeatRule;
  final String? location;
  final EventColors eventColor;
  final String createdBy;
  final String? partnershipId;
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
      'is_cycle_event': isCycleEvent,
      'start_date': Timestamp.fromDate(_startDate),
      'end_date': _endDate != null ? Timestamp.fromDate(_endDate) : null,
      'all_day': allDay,
      'repeat_rule': repeatRule.toMap(),
      'location': location,
      'event_color': eventColor.name,
      'created_by': createdBy,
      'partnership_id': partnershipId,
      'created_at': Timestamp.fromDate(_createdAt),
      'updated_at': Timestamp.fromDate(_updatedAt),
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? notes,
    bool? isCycleEvent,
    DateTime? startDate,
    DateTime? endDate,
    bool? allDay,
    RepeatRule? repeatRule,
    String? location,
    EventColors? eventColor,
    String? createdBy,
    String? partnershipId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      isCycleEvent: isCycleEvent ?? this.isCycleEvent,
      startDate: startDate ?? _startDate,
      endDate: endDate ?? _endDate,
      allDay: allDay ?? this.allDay,
      repeatRule: repeatRule ?? this.repeatRule,
      location: location ?? this.location,
      eventColor: eventColor ?? this.eventColor,
      createdBy: createdBy ?? this.createdBy,
      partnershipId: partnershipId ?? this.partnershipId,
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
