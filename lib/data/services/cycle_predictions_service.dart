import 'dart:math';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final cyclePredictionsServiceProvider = Provider.autoDispose(
  (ref) => const CyclePredictionsService(),
);

class CyclePredictionsService with LocalizationsMixin {
  const CyclePredictionsService();

  static const _defaultCycleLength = 28;
  static const _maxCycleLengthDeviation = 14.0;
  static const _minCycleGap = 15;
  static const _maxCycleGap = 45;
  static const _irregularityThreshold = 4.0;
  static const _ovulationDayBeforePeriod = 14;
  static const _baseFertileWindowDays = 6;
  static const _defaultPeriodLength = 4;
  static const _minPeriodDays = 1;
  static const _maxPeriodDays = 10;
  static const _consecutiveDayThreshold = 1;
  static const _ovulationWindowExtensionDivisor = 2;
  static const _maxOvulationWindowExtension = 3;
  static const _periodExtensionDivisor = 4;
  static const _maxPeriodExtension = 2;

  List<CycleLog> predictUpcomingCycles(List<CycleLog> logs, DateTime now) {
    final periodLogs = _getSortedActualPeriodLogs(logs);
    if (periodLogs.isEmpty) throw ArgumentError(l10n.noPeriodDataError);

    final periodStartDates = _extractPeriodStartDates(periodLogs);
    final avgCycleLength = _calculateAverageCycleLength(periodStartDates);
    final stdDev = _calculateCycleStandardDeviation(periodStartDates);
    final avgPeriodDays = _calculateAveragePeriodDaysFromDates(
      periodLogs,
      periodStartDates,
    );
    final isIrregular = stdDev > _irregularityThreshold;
    final lastPeriodDate = periodLogs.last.date;
    final baseNextPeriodStart = lastPeriodDate;
    var nextPeriodStart = _adjustNextPeriodForSymptoms(
      logs,
      baseNextPeriodStart,
      now,
    );
    final random = isIrregular ? Random(now.millisecondsSinceEpoch) : null;

    final predictions = <CycleLog>[];

    final historicalOvulations = _generateHistoricalOvulationPredictions(
      periodLogs,
    );
    predictions.addAll(historicalOvulations);

    for (var i = 0; i < 6; i++) {
      final cycleId = 'predicted_cycle_$i';
      final cycleLength = _getPredictedCycleLength(
        avgCycleLength,
        stdDev,
        isIrregular,
        random,
      );

      nextPeriodStart = nextPeriodStart.add(cycleLength.days);

      predictions.addAll(
        _generatePredictedPeriodLogs(
          nextPeriodStart,
          cycleId,
          avgPeriodDays,
          isIrregular,
          stdDev,
        ),
      );

      predictions.addAll(
        _generatePredictedOvulationWindow(
          nextPeriodStart,
          cycleId,
          isIrregular,
          stdDev,
        ),
      );
    }

    return predictions;
  }

  double _calculateAverageCycleLength(List<DateTime> periodStartDates) {
    if (periodStartDates.length < 2) {
      return _defaultCycleLength.toDouble();
    }

    final gaps = <int>[];

    for (var i = 1; i < periodStartDates.length; i++) {
      final diff = periodStartDates[i]
          .difference(periodStartDates[i - 1])
          .inDays;
      if (diff >= _minCycleGap && diff <= _maxCycleGap) {
        gaps.add(diff);
      }
    }

    if (gaps.isEmpty) {
      return _defaultCycleLength.toDouble();
    }

    return gaps.average;
  }

  double _calculateCycleStandardDeviation(List<DateTime> periodStartDates) {
    if (periodStartDates.length < 2) return 0.0;

    final gaps = <int>[];
    for (var i = 1; i < periodStartDates.length; i++) {
      final diff = periodStartDates[i]
          .difference(periodStartDates[i - 1])
          .inDays;

      if (diff >= _minCycleGap && diff <= _maxCycleGap) {
        gaps.add(diff);
      }
    }

    if (gaps.isEmpty || gaps.length < 2) return 0.0;

    final avg = gaps.average;
    return _calculateStandardDeviation(gaps, avg);
  }

  int _calculateAveragePeriodDaysFromDates(
    List<CycleLog> periodLogs,
    List<DateTime> periodStartDates,
  ) {
    if (periodStartDates.isEmpty) throw ArgumentError(l10n.noPeriodDataError);

    final periodGroups = _groupPeriodEventsByProximity(periodLogs);
    if (periodGroups.isEmpty) throw ArgumentError(l10n.noPeriodDataError);

    final cyclePeriodDays = <int>[];

    for (final group in periodGroups) {
      if (group.isNotEmpty) cyclePeriodDays.add(group.length);
    }

    if (cyclePeriodDays.isEmpty) return _defaultPeriodLength;

    return cyclePeriodDays.average.round();
  }

  List<List<CycleLog>> _groupPeriodEventsByProximity(List<CycleLog> events) {
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

  double _calculateStandardDeviation(List<int> gaps, double mean) {
    final variance = gaps.map((g) => pow(g - mean, 2)).sum / (gaps.length - 1);
    return sqrt(variance);
  }

  List<DateTime> _extractPeriodStartDates(List<CycleLog> periodLogs) {
    if (periodLogs.isEmpty) throw ArgumentError(l10n.noPeriodDataError);

    final periodGroups = _groupPeriodEventsByProximity(periodLogs);
    if (periodGroups.isEmpty) {
      throw ArgumentError(l10n.noPeriodDataError);
    }

    return periodGroups.map((group) => group.first.date).toList();
  }

  DateTime _adjustNextPeriodForSymptoms(
    List<CycleLog> allLogs,
    DateTime lastPeriodDate,
    DateTime now,
  ) {
    final cutoffDate = now.subtract(
      7.days,
    ); // look back 7 days for recent symptoms

    final hasRecentCramps = allLogs.any(
      (log) =>
          log.date.isAfter(cutoffDate) &&
          log.type == LogType.symptom &&
          !log.isPrediction &&
          log.symptoms?.contains('cramps') == true,
    );

    final adjustedDate = hasRecentCramps
        ? lastPeriodDate.subtract(
            1.days,
          ) // adjust period start by 1 day if cramps detected
        : lastPeriodDate;

    if (adjustedDate.isBefore(now.subtract(60.days))) {
      // prevent predictions more than 60 days in the past
      throw ArgumentError(l10n.unableToDetermineCycleError);
    }

    return adjustedDate;
  }

  int _getPredictedCycleLength(
    double avgCycleLength,
    double stdDev,
    bool isIrregular,
    Random? rand,
  ) {
    if (avgCycleLength < _minCycleGap || avgCycleLength > _maxCycleGap) {
      throw ArgumentError(l10n.unableToDetermineCycleError);
    }

    if (!isIrregular) return avgCycleLength.round();

    final deviation =
        (rand!.nextDouble() * 2 - 1) * min(stdDev, _maxCycleLengthDeviation);
    final predictedLength = (avgCycleLength + deviation).round();

    if (predictedLength < _minCycleGap || predictedLength > _maxCycleGap) {
      return avgCycleLength.round();
    }

    return predictedLength;
  }

  List<CycleLog> _generatePredictedOvulationWindow(
    DateTime nextPeriodStart,
    String cycleId,
    bool isIrregular,
    double stdDev,
  ) {
    final cycleLength = _getPredictedCycleLength(
      _defaultCycleLength.toDouble(),
      stdDev,
      isIrregular,
      isIrregular ? Random(nextPeriodStart.millisecondsSinceEpoch) : null,
    );
    final previousPeriodStart = nextPeriodStart.subtract(cycleLength.days);
    final ovulationDate = previousPeriodStart.add(
      _ovulationDayBeforePeriod.days,
    );

    final windowExtension = isIrregular
        ? (stdDev / _ovulationWindowExtensionDivisor)
              .clamp(0, _maxOvulationWindowExtension)
              .round()
        : 0;

    final fertileStart = ovulationDate.subtract(
      (5 + windowExtension)
          .days, // fertile window starts 5 days before ovulation
    );

    final windowDays = _baseFertileWindowDays + windowExtension;

    return List.generate(windowDays, (i) {
      final date = fertileStart.add(i.days);
      return CycleLog.ovulation(
        id: '${cycleId}_ovulation_$i',
        date: date,
        createdBy: 'system',
        ownedBy: 'system',
        users: [],
        isPrediction: true,
      );
    });
  }

  List<CycleLog> _generatePredictedPeriodLogs(
    DateTime start,
    String cycleId,
    int avgPeriodDays,
    bool isIrregular,
    double stdDev,
  ) {
    if (avgPeriodDays <= 0) {
      throw ArgumentError(l10n.unableToDetermineCycleError);
    }

    final periodExtension = isIrregular
        ? (stdDev / _periodExtensionDivisor)
              .clamp(0, _maxPeriodExtension)
              .round()
        : 0;
    final periodDays = (avgPeriodDays + periodExtension).clamp(
      _minPeriodDays,
      _maxPeriodDays,
    );

    return List.generate(periodDays, (i) {
      final date = start.add(i.days);
      return CycleLog.period(
        id: '${cycleId}_period_$i',
        date: date,
        flow: i < 2
            ? FlowIntensity.medium
            : FlowIntensity.light, // first 2 days are heavier flow
        createdBy: 'system',
        ownedBy: 'system',
        users: [],
        isPrediction: true,
      );
    });
  }

  List<CycleLog> _generateHistoricalOvulationPredictions(
    List<CycleLog> periodLogs,
  ) {
    if (periodLogs.length < 2) return [];

    final periodGroups = _groupPeriodEventsByProximity(periodLogs);
    if (periodGroups.length < 2) return [];

    final historicalOvulations = <CycleLog>[];

    for (var i = 0; i < periodGroups.length - 1; i++) {
      final currentPeriodGroup = periodGroups[i];
      final nextPeriodGroup = periodGroups[i + 1];

      final currentPeriodStart = currentPeriodGroup.first.date;
      final nextPeriodStart = nextPeriodGroup.first.date;

      final cycleLength = nextPeriodStart.difference(currentPeriodStart).inDays;

      if (cycleLength >= _minCycleGap && cycleLength <= _maxCycleGap) {
        final ovulationDate = nextPeriodStart.subtract(
          _ovulationDayBeforePeriod.days,
        );

        if (ovulationDate.isBefore(nextPeriodStart)) {
          final fertileStart = ovulationDate.subtract(5.days);

          for (var j = 0; j < _baseFertileWindowDays; j++) {
            final date = fertileStart.add(j.days);
            if (date.isAfter(
                  currentPeriodStart.add(currentPeriodGroup.length.days),
                ) &&
                date.isBefore(nextPeriodStart)) {
              historicalOvulations.add(
                CycleLog.ovulation(
                  id: 'historical_ovulation_${i}_$j',
                  date: date,
                  createdBy: 'system',
                  ownedBy: 'system',
                  users: [],
                  isPrediction: true,
                ),
              );
            }
          }
        }
      }
    }

    return historicalOvulations;
  }

  List<CycleLog> _getSortedActualPeriodLogs(List<CycleLog> logs) {
    return logs
        .where((l) => l.type == LogType.period && !l.isPrediction)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
