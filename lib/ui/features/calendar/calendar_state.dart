part of 'calendar_cubit.dart';

class CalendarState {
  const CalendarState({
    required this.focusedDay,
    required this.focusedDayEvents,
    required this.loading,
  });

  factory CalendarState.initial() => CalendarState(
    focusedDay: DateTime.now(),
    focusedDayEvents: [],
    loading: false,
  );

  final DateTime focusedDay;
  final List<CalendarEvent> focusedDayEvents;
  final bool loading;

  CalendarState copyWith({
    DateTime? focusedDay,
    List<CalendarEvent>? focusedDayEvents,
    bool? loading,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      focusedDayEvents: focusedDayEvents ?? this.focusedDayEvents,
      loading: loading ?? this.loading,
    );
  }
}
