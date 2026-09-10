import 'package:bebi_app/features/calendar/data/repeat_rule_dto.dart';
import 'package:bebi_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension CalendarEventDto on CalendarEvent {
  static CalendarEvent fromFirestore(DocumentSnapshot doc) {
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
      repeatRule: RepeatRuleDto.fromMap(
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
}
