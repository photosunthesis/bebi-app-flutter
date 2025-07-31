import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';

class RecurringCalendarEventsService {
  RecurringCalendarEventsService();

  static const _maxOccurrences = 1000;
  final _cache = <String, CalendarEvent>{};

  List<CalendarEvent> generateRecurringEventsInWindow(
    List<CalendarEvent> events,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final generatedEvents = <CalendarEvent>[];
    final filteredEvents = events
        .where((e) => e.repeatRule.frequency != RepeatFrequency.doNotRepeat)
        .toList();

    for (final event in filteredEvents) {
      final recurringEvents = _generateRecurringEvents(
        baseEvent: event,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      for (final instance in recurringEvents) {
        final key = _instanceKey(event.id, instance.date);

        if (_cache.containsKey(key)) {
          generatedEvents.add(_cache[key]!);
        } else {
          _cache[key] = instance;
          generatedEvents.add(instance);
        }
      }
    }

    return generatedEvents;
  }

  String _instanceKey(String eventId, DateTime date) {
    return '${eventId}_${date.millisecondsSinceEpoch}';
  }

  List<CalendarEvent> _generateRecurringEvents({
    required CalendarEvent baseEvent,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    final events = <CalendarEvent>[];
    var currentDate = baseEvent.date;
    var occurrenceCount = 0;

    while (currentDate.isBefore(windowEnd) &&
        occurrenceCount < _maxOccurrences) {
      if (_isDateInWindow(currentDate, windowStart, windowEnd)) {
        events.add(
          baseEvent.copyWith(
            recurringEventId: _instanceKey(baseEvent.id, currentDate),
            date: currentDate,
          ),
        );
      }

      currentDate = _getNextOccurrence(currentDate, baseEvent.repeatRule);
      occurrenceCount++;

      if (_shouldStopRepeating(
        baseEvent.repeatRule,
        currentDate,
        occurrenceCount,
      )) {
        break;
      }
    }

    return events;
  }

  DateTime _getNextOccurrence(DateTime current, RepeatRule rule) {
    return switch (rule.frequency) {
      RepeatFrequency.daily => current.add(Duration(days: rule.interval ?? 1)),
      RepeatFrequency.weekly => current.add(
        Duration(days: 7 * (rule.interval ?? 1)),
      ),
      RepeatFrequency.monthly => DateTime(
        current.year,
        current.month + (rule.interval ?? 1),
        current.day,
        current.hour,
        current.minute,
      ),
      RepeatFrequency.yearly => DateTime(
        current.year + (rule.interval ?? 1),
        current.month,
        current.day,
        current.hour,
        current.minute,
      ),
      _ => current,
    };
  }

  bool _shouldStopRepeating(
    RepeatRule rule,
    DateTime currentDate,
    int occurrenceCount,
  ) {
    if (rule.endDate != null && currentDate.isAfter(rule.endDate!)) {
      return true;
    }
    if (rule.occurrences != null && occurrenceCount >= rule.occurrences!) {
      return true;
    }
    return false;
  }

  bool _isDateInWindow(
    DateTime date,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    return !date.isBefore(windowStart) && !date.isAfter(windowEnd);
  }

  List<CalendarEvent> mergeRecurringEvents(
    List<CalendarEvent> existing,
    List<CalendarEvent> newEvents,
  ) {
    final merged = <String, CalendarEvent>{};
    for (final event in existing) {
      merged[event.id] = event;
    }
    for (final event in newEvents) {
      merged[event.id] = event;
    }
    return merged.values.toList();
  }

  List<CalendarEvent> sortRecurringEvents(List<CalendarEvent> events) {
    events.sort((a, b) {
      if (a.allDay && !b.allDay) return -1;
      if (!a.allDay && b.allDay) return 1;
      return a.startTime.compareTo(b.startTime);
    });
    return events;
  }

  List<CalendarEvent> getFocusedDayEvents(
    DateTime focusedDay,
    List<CalendarEvent> events,
    List<CalendarEvent> recurringEvents,
  ) {
    final dayEvents = <CalendarEvent>[];

    final nonRecurring = events
        .where(
          (e) =>
              e.repeatRule.frequency == RepeatFrequency.doNotRepeat &&
              e.date.isSameDay(focusedDay),
        )
        .map((e) => e.copyWith(date: e.date, recurringEventId: null))
        .toList();

    final recurring = recurringEvents
        .where((e) => e.date.isSameDay(focusedDay))
        .toList();

    dayEvents.addAll(nonRecurring);
    dayEvents.addAll(recurring);

    return sortRecurringEvents(dayEvents);
  }

  void clearCache() {
    _cache.clear();
  }
}
