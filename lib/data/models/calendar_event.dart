import 'dart:ui';

import 'package:bebi_app/constants/hive_constants.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'calendar_event.freezed.dart';
part 'calendar_event.g.dart';

@HiveType(typeId: HiveTypeIds.cycleEventType)
enum CycleEventType {
  @HiveField(0)
  period,
  @HiveField(1)
  fertile,
}

@freezed
abstract class CalendarEvent with _$CalendarEvent {
  const CalendarEvent._();

  @HiveType(typeId: HiveTypeIds.calendarEvent)
  const factory CalendarEvent({
    @HiveField(0) required String id,
    @HiveField(1) required String title,
    @HiveField(2) String? notes,
    @HiveField(3) @Default(false) bool isCycleEvent,
    @HiveField(4) required DateTime date,
    @HiveField(5) required DateTime startTime,
    @HiveField(6) DateTime? endTime,
    @HiveField(7) @Default(false) bool allDay,
    @HiveField(8) required RepeatRule repeatRule,
    @HiveField(9) String? location,
    @HiveField(10) required EventColors eventColor,
    @HiveField(11) required String createdBy,
    @HiveField(12) required List<String> users,
    @HiveField(13) required DateTime createdAt,
    @HiveField(14) required DateTime updatedAt,
  }) = _CalendarEvent;

  factory CalendarEvent.cycle({
    required String id,
    required String title,
    String? notes,
    required DateTime date,
    required DateTime startTime,
    DateTime? endTime,
    required CycleEventType cycleEventType,
    required bool isPrediction,
  }) {
    return CalendarEvent(
      id: id,
      title: title,
      notes:
          '${cycleEventType == CycleEventType.period ? 'Period' : 'Fertile'}|##|${isPrediction ? 'prediction' : 'actual'}',
      isCycleEvent: true,
      date: date,
      startTime: startTime,
      endTime: endTime,
      allDay: true,
      repeatRule: const RepeatRule(frequency: RepeatFrequency.doNotRepeat),
      eventColor: EventColors.red,
      createdBy: '',
      users: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

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

  DateTime get dateLocal => date.toLocal();
  DateTime get startTimeLocal => startTime.toLocal();
  DateTime? get endTimeLocal => endTime?.toLocal();
  DateTime get createdAtLocal => createdAt.toLocal();
  DateTime get updatedAtLocal => updatedAt.toLocal();

  Color get color => eventColor.color;

  /// Returns the cycle event type.
  ///
  /// Throws an exception if the event is not a cycle event.
  CycleEventType get cycleEventType {
    assert(isCycleEvent, 'Event is not a cycle event.');
    return notes!.split('|##|')[0] == 'Period'
        ? CycleEventType.period
        : CycleEventType.fertile;
  }

  /// Returns the prediction flag.
  ///
  /// Throws an exception if the event is not a cycle event.
  bool get isPrediction {
    assert(isCycleEvent, 'Event is not a cycle event.');
    return notes!.split('|##|')[1] == 'prediction';
  }

  Map<String, dynamic> toFirestore() {
    return {
      // ID is handled by Firestore
      'title': title,
      'notes': notes,
      'is_cycle_event': isCycleEvent,
      'date': Timestamp.fromDate(date),
      'start_time': Timestamp.fromDate(startTime),
      'end_time': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'all_day': allDay,
      'repeat_rule': repeatRule.toMap(),
      'location': location,
      'event_color': eventColor.name,
      'created_by': createdBy,
      'users': users,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
