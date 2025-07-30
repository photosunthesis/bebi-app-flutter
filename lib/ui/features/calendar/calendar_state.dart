part of 'calendar_cubit.dart';

class CalendarState {
  const CalendarState({
    required this.focusedDay,
    required this.focusedDayEvents,
    required this.focusedMonthEvents,
    this.loading = false,
    this.error,
  });

  factory CalendarState.initial() => CalendarState(
    focusedDay: DateTime.now(),
    focusedDayEvents: [],
    focusedMonthEvents: [],
    loading: false,
  );

  final DateTime focusedDay;
  final List<CalendarEvent> focusedDayEvents;
  final List<CalendarEvent> focusedMonthEvents;
  final bool loading;
  final String? error;

  CalendarState copyWith({
    DateTime? focusedDay,
    List<CalendarEvent>? focusedDayEvents,
    List<CalendarEvent>? focusedMonthEvents,
    bool? loading,
    String? error,
    bool didErrorChange = false,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      focusedDayEvents: focusedDayEvents ?? this.focusedDayEvents,
      focusedMonthEvents: focusedMonthEvents ?? this.focusedMonthEvents,
      loading: loading ?? this.loading,
      error: didErrorChange ? error : this.error,
    );
  }
}
