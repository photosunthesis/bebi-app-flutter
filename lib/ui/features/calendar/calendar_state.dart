part of 'calendar_cubit.dart';

sealed class CalendarState {
  const CalendarState();
}

class CalendarLoadingState extends CalendarState {
  const CalendarLoadingState();
}

class CalendarLoadedState extends CalendarState {
  const CalendarLoadedState({
    required this.focusedDay,
    required this.events,
    required this.focusedDayEvents,
  });
  final DateTime focusedDay;
  final List<CalendarEvent> events;
  final List<CalendarEvent> focusedDayEvents;
}

class CalendarErrorState extends CalendarState {
  const CalendarErrorState(this.error);
  final String error;
}
