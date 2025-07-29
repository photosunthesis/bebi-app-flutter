part of 'calendar_event_form_cubit.dart';

class CalendarEventFormState {
  const CalendarEventFormState({
    this.calendarEventId,
    this.calendarEvent,
    this.loading = false,
    this.success = false,
    this.error,
  });

  final String? calendarEventId;
  final CalendarEvent? calendarEvent;
  final bool loading;
  final bool success;
  final String? error;

  CalendarEventFormState copyWith({
    String? calendarEventId,
    CalendarEvent? calendarEvent,
    bool? loading,
    bool? success,
    String? error,
  }) {
    return CalendarEventFormState(
      calendarEventId: calendarEventId ?? this.calendarEventId,
      calendarEvent: calendarEvent ?? this.calendarEvent,
      loading: loading ?? this.loading,
      success: success ?? this.success,
      error: error ?? this.error,
    );
  }
}
