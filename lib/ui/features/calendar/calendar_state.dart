part of 'calendar_cubit.dart';

class CalendarState {
  const CalendarState({
    required this.focusedDay,
    this.events = const AsyncData([]),
  });

  final DateTime focusedDay;
  final AsyncValue<List<CalendarEvent>> events;

  List<CalendarEvent> get focusedDayEvents {
    return events
        .map(data: (data) => data, orElse: () => <CalendarEvent>[])
        .where((event) => event.startDate.isSameDay(focusedDay))
        .toList();
  }

  CalendarState copyWith({
    DateTime? focusedDay,
    AsyncValue<List<CalendarEvent>>? events,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      events: events ?? this.events,
    );
  }
}
