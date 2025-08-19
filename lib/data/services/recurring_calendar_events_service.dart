import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:injectable/injectable.dart';

@injectable
class RecurringCalendarEventsService {
  RecurringCalendarEventsService();

  final Map<DateTime, List<CalendarEvent>> _cache = {};
  final Map<String, CalendarEvent> _baseEventCache = {};
  final Map<String, Set<String>> _generatedWindowsPerEvent = {};
  final Map<String, int> _eventHashes = {};

  static const int _maxOccurrences = 1000;
  static const String _recurringPrefix = 'recurring';

  List<CalendarEvent> generateRecurringEventsInWindow(
    List<CalendarEvent> events,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final windowRangeKey = _windowRangeKey(windowStart, windowEnd);
    final generatedEvents = <CalendarEvent>[];

    final filteredEvents = events.where((e) => e.isRecurring).toList();

    for (final event in filteredEvents) {
      _baseEventCache[event.id] = event;
      final currentHash = _computeEventHash(event);
      final previousHash = _eventHashes[event.id];

      final hasWindow =
          _generatedWindowsPerEvent[event.id]?.contains(windowRangeKey) ??
          false;

      if (hasWindow && currentHash == previousHash) {
        continue;
      }

      final recurringEvents = _generateRecurringEvents(
        baseEvent: event,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );

      for (final instance in recurringEvents) {
        final dateKey = _startOfDay(instance.date);
        _cache.putIfAbsent(dateKey, () => []).add(instance);
        generatedEvents.add(instance);
      }

      _generatedWindowsPerEvent
          .putIfAbsent(event.id, () => {})
          .add(windowRangeKey);
      _eventHashes[event.id] = currentHash;
    }

    return generatedEvents;
  }

  String _windowRangeKey(DateTime start, DateTime end) =>
      '${start.millisecondsSinceEpoch}_${end.millisecondsSinceEpoch}';

  int _computeEventHash(CalendarEvent event) => event.hashCode;

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _instanceKey(String eventId, DateTime date) =>
      '$_recurringPrefix:$eventId:${date.millisecondsSinceEpoch}';

  List<CalendarEvent> _generateRecurringEvents({
    required CalendarEvent baseEvent,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    final events = <CalendarEvent>[];
    final seenDates = <DateTime>{};

    var currentDate = getNextOccurrence(baseEvent.date, baseEvent.repeatRule);
    var occurrenceCount = 1;

    while (currentDate.isBefore(windowEnd) &&
        occurrenceCount < _maxOccurrences &&
        !_shouldStopRepeating(
          baseEvent.repeatRule,
          currentDate,
          occurrenceCount,
        )) {
      final dateKey = _startOfDay(currentDate);

      if (_isDateInWindow(currentDate, windowStart, windowEnd) &&
          !_isExcludedDate(currentDate, baseEvent.repeatRule) &&
          !seenDates.contains(dateKey)) {
        seenDates.add(dateKey);
        events.add(
          baseEvent.copyWith(
            recurringEventId: _instanceKey(baseEvent.id, currentDate),
            date: currentDate,
          ),
        );
      }

      currentDate = getNextOccurrence(currentDate, baseEvent.repeatRule);
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

  DateTime getNextOccurrence(DateTime current, RepeatRule rule) {
    return switch (rule.frequency) {
      RepeatFrequency.daily => current.add(1.days),
      RepeatFrequency.weekly => current.add(7.days),
      RepeatFrequency.monthly => DateTime(
        current.year,
        current.month + 1,
        current.day,
        current.hour,
        current.minute,
      ),
      RepeatFrequency.yearly => DateTime(
        current.year + 1,
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

  bool _isExcludedDate(DateTime date, RepeatRule rule) {
    if (rule.excludedDates == null) return false;
    return rule.excludedDates!.any((d) => d.isSameDay(date));
  }

  bool _isDateInWindow(DateTime date, DateTime start, DateTime end) =>
      !date.isBefore(start) && !date.isAfter(end);

  List<CalendarEvent> sortRecurringEvents(List<CalendarEvent> events) {
    events.sort((a, b) {
      if (a.allDay && !b.allDay) return -1;
      if (!a.allDay && b.allDay) return 1;
      return a.startTime.compareTo(b.startTime);
    });
    return events;
  }

  List<CalendarEvent> mergeRecurringEvents(
    List<CalendarEvent> existing,
    List<CalendarEvent> newEvents,
  ) {
    final merged = <String, CalendarEvent>{};

    for (final event in existing) {
      if (event.isRecurring) {
        _baseEventCache[event.id] = event;
        if (event.recurringEventId != null) {
          merged[event.recurringEventId!] = event;
        }
      } else {
        merged[event.id] = event;
      }
    }

    for (final event in newEvents) {
      if (event.isRecurring) {
        _baseEventCache[event.id] = event;
        if (event.recurringEventId != null) {
          merged[event.recurringEventId!] = event;
          final dateKey = _startOfDay(event.date);
          _cache.putIfAbsent(dateKey, () => []).add(event);
        }
      } else {
        merged[event.id] = event;
      }
    }

    return merged.values.toList();
  }

  void updateEventInCache(CalendarEvent event) {
    if (event.isRecurring) {
      _baseEventCache[event.id] = event;
      _regenerateEventsForBaseEvent(event);
    }
  }

  void _regenerateEventsForBaseEvent(CalendarEvent baseEvent) {
    final dateKeysToRemove = _cache.keys.where((key) {
      final events = _cache[key];
      return events?.any((e) => e.id == baseEvent.id) ?? false;
    }).toList();

    for (final key in dateKeysToRemove) {
      _cache.remove(key);
    }

    _generatedWindowsPerEvent.remove(baseEvent.id);
    _eventHashes.remove(baseEvent.id);
  }

  void removeEventFromCache(String eventId, [DateTime? specificDate]) {
    if (specificDate != null) {
      final key = _startOfDay(specificDate);
      _cache[key]?.removeWhere((e) => e.id == eventId);
    } else {
      _baseEventCache.remove(eventId);
      _eventHashes.remove(eventId);
      _generatedWindowsPerEvent.remove(eventId);

      for (final key in _cache.keys.toList()) {
        _cache[key]?.removeWhere((e) => e.id == eventId);
        if (_cache[key]?.isEmpty ?? false) {
          _cache.remove(key);
        }
      }
    }
  }

  void clearCache() {
    _cache.clear();
    _baseEventCache.clear();
    _generatedWindowsPerEvent.clear();
    _eventHashes.clear();
  }
}
