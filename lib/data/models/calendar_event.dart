import 'dart:ui';

import 'package:bebi_app/constants/hive_constants.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'calendar_event.freezed.dart';
part 'calendar_event.g.dart';

@freezed
abstract class CalendarEvent with _$CalendarEvent {
  const CalendarEvent._();

  @HiveType(typeId: HiveTypeIds.calendarEvent)
  const factory CalendarEvent({
    @HiveField(0) required String id,
    String? recurringEventId, // Used only in UI, not saved in Firestore
    @HiveField(1) required String title,
    @HiveField(2) String? notes,
    @HiveField(3) required DateTime date,
    @HiveField(4) required DateTime startTime,
    @HiveField(5) DateTime? endTime,
    @HiveField(6) @Default(false) bool allDay,
    @HiveField(7) required RepeatRule repeatRule,
    @HiveField(8) required EventColor eventColor,
    @HiveField(9) required List<String> users,
    @HiveField(10) required String createdBy,
    @HiveField(11) required String updatedBy,
    @HiveField(12) required DateTime createdAt,
    @HiveField(13) required DateTime updatedAt,
  }) = _CalendarEvent;

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

  DateTime get dateLocal => date.toLocal();
  DateTime get startTimeLocal => startTime.toLocal();
  DateTime? get endTimeLocal => endTime?.toLocal();
  DateTime get createdAtLocal => createdAt.toLocal();
  DateTime get updatedAtLocal => updatedAt.toLocal();
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

  Map<String, dynamic> toFirestore() {
    return {
      // ID is handled by Firestore
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
}
