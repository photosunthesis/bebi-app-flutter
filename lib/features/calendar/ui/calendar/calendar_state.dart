part of 'calendar_cubit.dart';

class CalendarState {
  const CalendarState({
    required this.focusedDay,
    this.events = const AsyncData([]),
    this.baseEvents = const AsyncData([]),
  });

  final DateTime focusedDay;
  final AsyncValue<List<CalendarEvent>> events;
  final AsyncValue<List<CalendarEvent>> baseEvents;

  List<CalendarEvent> get focusedDayEvents {
    return events
        .maybeMap(data: (data) => data, orElse: () => <CalendarEvent>[])
        .where((event) => event.startDate.isSameDay(focusedDay))
        .toList();
  }

  CalendarState copyWith({
    DateTime? focusedDay,
    AsyncValue<List<CalendarEvent>>? events,
    AsyncValue<List<CalendarEvent>>? baseEvents,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      events: events ?? this.events,
      baseEvents: baseEvents ?? this.baseEvents,
    );
  }
}
