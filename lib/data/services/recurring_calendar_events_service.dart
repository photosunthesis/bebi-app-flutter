import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';

class RecurringCalendarEventsService {
  RecurringCalendarEventsService();

  final _cache = <String, CalendarEvent>{};
  final _baseEventCache = <String, CalendarEvent>{};
  final _generatedWindowRanges = <String>{};
  static const _maxOccurrences = 1000;
  static const _recurringPrefix = 'recurring';

  String _windowRangeKey(DateTime start, DateTime end) {
    return '${start.millisecondsSinceEpoch}_${end.millisecondsSinceEpoch}';
  }

  String _instanceKey(String eventId, DateTime date) {
    return '$_recurringPrefix:$eventId:${date.millisecondsSinceEpoch}';
  }

  List<CalendarEvent> generateRecurringEventsInWindow(
    List<CalendarEvent> events,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final windowRangeKey = _windowRangeKey(windowStart, windowEnd);
    final generatedEvents = <CalendarEvent>[];

    final filteredEvents = events
        .where((e) => e.repeatRule.frequency != RepeatFrequency.doNotRepeat)
        .toList();

    for (final event in filteredEvents) {
      _baseEventCache[event.id] = event;
    }

    if (_generatedWindowRanges.contains(windowRangeKey)) {
      return _getEventsFromCacheForWindow(windowStart, windowEnd);
    }

    for (final event in filteredEvents) {
      final recurringEvents = _generateRecurringEvents(
        baseEvent: event,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      for (final instance in recurringEvents) {
        final key = _instanceKey(event.id, instance.date);
        _cache[key] = instance;
        generatedEvents.add(instance);
      }
    }

    _generatedWindowRanges.add(windowRangeKey);
    return generatedEvents;
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
      final key = event.recurringEventId ?? event.id;
      merged[key] = event;

      if (event.repeatRule.frequency != RepeatFrequency.doNotRepeat) {
        _baseEventCache[event.id] = event;
      }
    }

    for (final event in newEvents) {
      final key = event.recurringEventId ?? event.id;
      merged[key] = event;

      if (event.repeatRule.frequency != RepeatFrequency.doNotRepeat) {
        _baseEventCache[event.id] = event;

        if (event.recurringEventId != null) {
          _cache[event.recurringEventId!] = event;
        }
      }
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

    final cachedRecurring = _getCachedEventsForDay(focusedDay);
    if (cachedRecurring.isNotEmpty) {
      dayEvents.addAll(nonRecurring);
      dayEvents.addAll(cachedRecurring);
      return sortRecurringEvents(dayEvents);
    }

    final recurring = recurringEvents
        .where((e) => e.date.isSameDay(focusedDay))
        .toList();

    dayEvents.addAll(nonRecurring);
    dayEvents.addAll(recurring);

    return sortRecurringEvents(dayEvents);
  }

  List<CalendarEvent> _getCachedEventsForDay(DateTime day) {
    return _cache.values.where((event) => event.date.isSameDay(day)).toList();
  }

  List<CalendarEvent> _getEventsFromCacheForWindow(
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    return _cache.values
        .where((event) => _isDateInWindow(event.date, windowStart, windowEnd))
        .toList();
  }

  void updateEventInCache(CalendarEvent event) {
    if (event.repeatRule.frequency != RepeatFrequency.doNotRepeat) {
      _baseEventCache[event.id] = event;

      final key = event.recurringEventId ?? _instanceKey(event.id, event.date);
      _cache[key] = event;

      _regenerateEventsForBaseEvent(event);
    }
  }

  void _regenerateEventsForBaseEvent(CalendarEvent baseEvent) {
    final keysToRemove = <String>[];

    for (final key in _cache.keys) {
      if (key.startsWith('$_recurringPrefix:${baseEvent.id}:')) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    _generatedWindowRanges.removeWhere((rangeKey) {
      // Remove any window keys that might be affected
      // TODO Track a mapping of eventId to window keys to be more precise
      return true;
    });
  }

  void removeEventFromCache(String eventId, {DateTime? specificDate}) {
    if (specificDate != null) {
      final instanceKey = _instanceKey(eventId, specificDate);
      _cache.remove(instanceKey);
    } else {
      _baseEventCache.remove(eventId);

      final keysToRemove = <String>[];
      for (final key in _cache.keys) {
        if (key.startsWith('$_recurringPrefix:$eventId:')) {
          keysToRemove.add(key);
        }
      }

      for (final key in keysToRemove) {
        _cache.remove(key);
      }
    }
  }

  void clearCache() {
    _cache.clear();
    _baseEventCache.clear();
    _generatedWindowRanges.clear();
  }
}
