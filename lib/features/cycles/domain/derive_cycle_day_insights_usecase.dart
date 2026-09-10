import 'package:bebi_app/features/cycles/domain/cycle_day_insights.dart';
import 'package:bebi_app/features/cycles/domain/cycle_log.dart';
import 'package:bebi_app/features/cycles/domain/group_period_events_by_proximity.dart';
import 'package:bebi_app/features/cycles/domain/no_period_data_exception.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeriveCycleDayInsightsUsecase {
  const DeriveCycleDayInsightsUsecase();

  CycleDayInsights call(DateTime date, List<CycleLog> events) {
    final sortedEvents = events.sortedBy((e) => e.date);
    final periodEvents = sortedEvents.where((e) => e.type == LogType.period);
    final ovulationEvents = sortedEvents.where(
      (e) => e.type == LogType.ovulation,
    );

    if (periodEvents.isEmpty) throw NoPeriodDataException();

    final periodGroups = groupPeriodEventsByProximity(periodEvents.toList());

    final currentPeriodGroup = _findCurrentPeriodGroup(date, periodGroups);
    final cycleStart = currentPeriodGroup.first.date;
    final nextPeriodGroup = _findNextPeriodGroup(
      periodGroups,
      currentPeriodGroup,
    );

    final nextCycleStart = nextPeriodGroup.first.date;

    final dayOfCycle = date.noTime().difference(cycleStart.noTime()).inDays + 1;
    final cycleLengthInDays = nextCycleStart
        .noTime()
        .difference(cycleStart.noTime())
        .inDays;

    final currentFertileWindow = _getCurrentFertileWindow(
      ovulationEvents.map((e) => e.date).toList(),
      cycleStart,
      nextCycleStart,
    );

    final cyclePhase = _getCyclePhase(date, sortedEvents.toList());
    final averagePeriodDurationInDays = _calculateAveragePeriodDays(
      periodGroups,
    );

    return CycleDayInsights(
      cyclePhase: cyclePhase,
      date: date,
      dayOfCycle: dayOfCycle,
      cycleLengthInDays: cycleLengthInDays,
      averagePeriodDurationInDays: averagePeriodDurationInDays,
      nextPeriodDates: nextPeriodGroup.map((log) => log.date).toList(),
      fertileDays: currentFertileWindow,
    );
  }

  List<CycleLog> _findCurrentPeriodGroup(
    DateTime date,
    List<List<CycleLog>> periodGroups,
  ) {
    final normalizedDate = date.noTime();

    for (final periodGroup in periodGroups) {
      final periodDates = periodGroup.map((log) => log.date.noTime()).toList();

      if (periodDates.any(
        (periodDate) =>
            periodDate.isAtSameMomentAs(normalizedDate) ||
            (periodDate.isBefore(normalizedDate) &&
                normalizedDate.difference(periodDate).inDays <= 7),
      )) {
        return periodGroup;
      }
    }

    for (var i = 0; i < periodGroups.length - 1; i++) {
      final currentGroup = periodGroups[i];
      final nextGroup = periodGroups[i + 1];
      final currentGroupEndDate = currentGroup
          .map((log) => log.date.noTime())
          .last;
      final nextGroupStartDate = nextGroup
          .map((log) => log.date.noTime())
          .first;

      if (normalizedDate.isAfter(currentGroupEndDate) &&
          normalizedDate.isBefore(nextGroupStartDate)) {
        return currentGroup;
      }
    }

    return periodGroups.first;
  }

  List<CycleLog> _findNextPeriodGroup(
    List<List<CycleLog>> periodGroups,
    List<CycleLog> currentPeriodGroup,
  ) {
    final currentIndex = periodGroups.indexOf(currentPeriodGroup);
    if (currentIndex < periodGroups.length - 1) {
      return periodGroups[currentIndex + 1];
    }
    return periodGroups.first;
  }

  List<DateTime> _getCurrentFertileWindow(
    List<DateTime> ovulationDates,
    DateTime cycleStart,
    DateTime? nextCycleStart,
  ) {
    if (ovulationDates.isEmpty) return [];
    if (nextCycleStart == null) {
      return ovulationDates.where((date) => date.isAfter(cycleStart)).toList();
    }
    return ovulationDates
        .where(
          (date) => date.isBefore(nextCycleStart) && date.isAfter(cycleStart),
        )
        .toList();
  }

  CyclePhase _getCyclePhase(DateTime date, List<CycleLog> allCycleLogs) {
    final normalizedDate = date.noTime();

    final periodLogs = allCycleLogs
        .where((log) => log.type == LogType.period)
        .map((log) => log.date.noTime())
        .toList();
    final ovulationLogs = allCycleLogs
        .where((log) => log.type == LogType.ovulation)
        .map((log) => log.date.noTime())
        .toList();

    if (periodLogs.any((periodDate) => periodDate.isSameDay(normalizedDate))) {
      return CyclePhase.period;
    }

    if (ovulationLogs.any(
      (ovulationDate) => ovulationDate.isSameDay(normalizedDate),
    )) {
      return CyclePhase.ovulation;
    }

    final previousPeriodDate = _findClosestDate(
      periodLogs.where((date) => date.isBefore(normalizedDate)),
      isLatest: true,
    );

    if (previousPeriodDate != null) {
      final ovulationAfterPreviousPeriod = _findClosestDate(
        ovulationLogs.where((date) => date.isAfter(previousPeriodDate)),
        isLatest: false,
      );

      if (ovulationAfterPreviousPeriod != null &&
          normalizedDate.isAfter(previousPeriodDate) &&
          normalizedDate.isBefore(ovulationAfterPreviousPeriod)) {
        return CyclePhase.follicular;
      }
    }

    return CyclePhase.luteal;
  }

  DateTime? _findClosestDate(
    Iterable<DateTime> dates, {
    required bool isLatest,
  }) {
    return dates.fold<DateTime?>(
      null,
      (prev, curr) =>
          prev == null || (isLatest ? curr.isAfter(prev) : curr.isBefore(prev))
          ? curr
          : prev,
    );
  }

  int _calculateAveragePeriodDays(List<List<CycleLog>> periodGroups) {
    final periodLengths = periodGroups.map((group) => group.length).toList();
    return periodLengths.average.round();
  }
}
