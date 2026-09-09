import 'package:bebi_app/features/calendar/domain/repeat_rule.dart';
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

enum EventColor { black, green, blue, yellow, pink, orange, red }
