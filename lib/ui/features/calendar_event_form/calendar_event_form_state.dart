part of 'calendar_event_form_cubit.dart';

@freezed
abstract class CalendarEventFormState with _$CalendarEventFormState {
  const factory CalendarEventFormState({
    String? calendarEventId,
    CalendarEvent? calendarEvent,
    @Default(false) bool loading,
    @Default(false) bool success,
    String? error,
  }) = _CalendarEventFormState;
}
