part of 'calendar_cubit.dart';

@freezed
abstract class CalendarState with _$CalendarState {
  const factory CalendarState({
    required DateTime focusedDay,
    required List<CalendarEvent> focusedDayEvents,
    required List<CalendarEvent> focusedMonthEvents,
    @Default(false) bool loading,
    String? error,
  }) = _CalendarState;

  factory CalendarState.initial() => CalendarState(
    focusedDay: DateTime.now(),
    focusedDayEvents: [],
    focusedMonthEvents: [],
    loading: false,
  );
}
