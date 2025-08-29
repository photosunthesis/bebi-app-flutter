part of 'calendar_cubit.dart';

class CalendarState {
  const CalendarState({
    required this.focusedDay,
    this.events = const [],
    this.focusedDayEvents = const [],
    this.isLoading = false,
    this.error,
  });

  final DateTime focusedDay;
  final List<CalendarEvent> events;
  final List<CalendarEvent> focusedDayEvents;
  final bool isLoading;
  final String? error;

  CalendarState copyWith({
    DateTime? focusedDay,
    List<CalendarEvent>? events,
    List<CalendarEvent>? focusedDayEvents,
    bool? isLoading,
    String? error,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      events: events ?? this.events,
      focusedDayEvents: focusedDayEvents ?? this.focusedDayEvents,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
