import 'dart:async';

import 'package:bebi_app/data/models/cycle_day_insights.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/prediction_confidence.dart';
import 'package:bebi_app/data/services/cycle_insights_prompt.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@injectable
class CycleDayInsightsService with LocalizationsMixin {
  const CycleDayInsightsService(
    this._generativeModel,
    @Named('ai_insights_box') this._aiInsightsBox,
  );

  static const _maxPeriodGapDays = 14;

  final GenerativeModel _generativeModel;
  final Box<String> _aiInsightsBox;

  CycleDayInsights getInsightsFromDateAndEvents(
    DateTime date,
    List<CycleLog> events,
  ) {
    final sortedEvents = events.sortedBy((e) => e.date);
    final periodEvents = sortedEvents.where((e) => e.type == LogType.period);
    final ovulationEvents = sortedEvents.where(
      (e) => e.type == LogType.ovulation,
    );

    if (periodEvents.isEmpty) {
      throw ArgumentError(l10n.noPeriodDataError);
    }

    final periodGroups = _groupPeriodEventsByProximity(periodEvents.toList());

    if (periodGroups.isEmpty) {
      throw ArgumentError(l10n.unableToDetermineCycleError);
    }

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

  List<List<CycleLog>> _groupPeriodEventsByProximity(List<CycleLog> events) {
    final periodGroups = <List<CycleLog>>[];

    for (final event in events) {
      final currentGroup = periodGroups.lastOrNull;
      // 14 days is the max distance between two period events
      if (currentGroup == null ||
          event.date.difference(currentGroup.last.date).inDays >
              _maxPeriodGapDays) {
        periodGroups.add([event]);
      } else {
        currentGroup.add(event);
      }
    }

    return periodGroups;
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
    if (periodGroups.isEmpty) {
      throw ArgumentError(l10n.noPeriodDataForCycleError);
    }

    final periodLengths = periodGroups.map((group) => group.length).toList();
    return periodLengths.average.round();
  }

  Future<String> generateAiInsights(
    CycleDayInsights cycleDayInsights, {
    required bool isCurrentUser,
    required String locale,
    PredictionConfidence? confidence,
    bool useCache = true,
  }) async {
    try {
      final date = cycleDayInsights.date.toIso8601String().substring(0, 10);
      final key = '${date}_${isCurrentUser ? 'self' : 'partner'}';
      final cachedInsights = _aiInsightsBox.get(key);
      if (cachedInsights != null && useCache) return cachedInsights;

      final prompt = CycleInsightsPrompt.generate(
        insights: cycleDayInsights,
        isCurrentUser: isCurrentUser,
        locale: locale,
        confidence: confidence,
      );

      final response = await _generativeModel.generateContent([
        Content.text(prompt),
      ]);

      if (response.text == null) throw ArgumentError();

      unawaited(_aiInsightsBox.put(key, response.text!));

      return response.text!;
    } catch (_) {
      throw ArgumentError(l10n.aiInsightsGenerationError);
    }
  }
}
