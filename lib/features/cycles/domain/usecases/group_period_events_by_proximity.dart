import 'package:bebi_app/features/cycles/domain/entities/cycle_log.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

// 14 days is the max distance between two period events
const _consecutiveDayThreshold = 14;

List<List<CycleLog>> groupPeriodEventsByProximity(List<CycleLog> events) {
  if (events.isEmpty) return [];

  final sortedEvents = events.toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final groups = <List<CycleLog>>[];

  for (final event in sortedEvents) {
    final group = groups.lastOrNull;
    if (group == null ||
        event.date.difference(group.last.date).inDays >
            _consecutiveDayThreshold) {
      groups.add([event]);
    } else {
      group.add(event);
    }
  }

  return groups;
}
