import 'dart:math';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

@injectable
class CyclePredictionsService {
  const CyclePredictionsService();

  static const _maxPredictions = 6;
  static const _defaultCycleLength = 28;
  static const _maxCycleLengthDeviation = 14.0;
  static const _minCycleGap = 15;
  static const _maxCycleGap = 45;
  static const _irregularityThreshold = 4.0;
  static const _ovulationDayBeforePeriod = 14;
  static const _baseFertileWindowDays = 6;
  static const _defaultPeriodLength = 4;
  static const _recentSymptomsLookbackDays = 7;
  static const _maxPastDateDays = 60;
  static const _minPeriodDays = 1;
  static const _maxPeriodDays = 10;
  static const _periodAdjustmentDays = 1;
  static const _consecutiveDayThreshold = 1;
  static const _ovulationWindowExtensionDivisor = 2;
  static const _maxOvulationWindowExtension = 3;
  static const _periodExtensionDivisor = 4;
  static const _maxPeriodExtension = 2;
  static const _ovulationWindowStartOffset = 5;
  static const _heavyFlowDays = 2;

  List<CycleLog> predictUpcomingCycles(List<CycleLog> logs, DateTime now) {
    final periodLogs = _getSortedActualPeriodLogs(logs);
    if (periodLogs.isEmpty) throw ArgumentError(l10n.noPeriodDataError);

    final cycleData = _preprocessCycleData(periodLogs, logs, now);
    final predictions = <CycleLog>[];
    var nextPeriodStart = cycleData.nextPeriodStart;

    for (var i = 0; i < _maxPredictions; i++) {
      final cycleId = 'predicted_cycle_$i';
      final cycleLength = _getPredictedCycleLength(
        cycleData.avgCycleLength,
        cycleData.stdDev,
        cycleData.isIrregular,
        cycleData.random,
      );

      nextPeriodStart = nextPeriodStart.add(cycleLength.days);

      predictions.addAll(
        _generatePredictedPeriodLogs(
          nextPeriodStart,
          cycleId,
          cycleData.avgPeriodDays,
          cycleData.isIrregular,
          cycleData.stdDev,
        ),
      );

      predictions.addAll(
        _generatePredictedOvulationWindow(
          nextPeriodStart,
          cycleId,
          cycleData.isIrregular,
          cycleData.stdDev,
        ),
      );
    }

    return predictions;
  }

  _CycleData _preprocessCycleData(
    List<CycleLog> periodLogs,
    List<CycleLog> allLogs,
    DateTime now,
  ) {
    final periodStartDates = _extractPeriodStartDates(periodLogs);
    final cycleStats = _calculateCycleStatisticsFromDates(periodStartDates);
    final avgPeriodDays = _calculateAveragePeriodDaysFromDates(
      periodLogs,
      periodStartDates,
    );
    final isIrregular = cycleStats.stdDev > _irregularityThreshold;
    final lastPeriodDate = periodLogs.last.date;
    final baseNextPeriodStart = lastPeriodDate;
    final nextPeriodStart = _adjustNextPeriodForSymptoms(
      allLogs,
      baseNextPeriodStart,
      now,
    );

    return _CycleData(
      avgCycleLength: cycleStats.avg,
      stdDev: cycleStats.stdDev,
      avgPeriodDays: avgPeriodDays,
      isIrregular: isIrregular,
      nextPeriodStart: nextPeriodStart,
      random: isIrregular ? Random(now.millisecondsSinceEpoch) : null,
    );
  }

  ({double avg, double stdDev}) _calculateCycleStatisticsFromDates(
    List<DateTime> periodStartDates,
  ) {
    if (periodStartDates.length < 2) {
      return (avg: _defaultCycleLength.toDouble(), stdDev: 0.0);
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
      return (avg: _defaultCycleLength.toDouble(), stdDev: 0.0);
    }

    final avg = gaps.average;
    final stdDev = gaps.length < 2
        ? 0.0
        : _calculateStandardDeviation(gaps, avg);

    return (avg: avg, stdDev: stdDev);
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
    final cutoffDate = now.subtract(_recentSymptomsLookbackDays.days);

    final hasRecentCramps = allLogs.any(
      (log) =>
          log.date.isAfter(cutoffDate) &&
          log.type == LogType.symptom &&
          !log.isPrediction &&
          log.symptoms?.contains('cramps') == true,
    );

    final adjustedDate = hasRecentCramps
        ? lastPeriodDate.subtract(_periodAdjustmentDays.days)
        : lastPeriodDate;

    if (adjustedDate.isBefore(now.subtract(_maxPastDateDays.days))) {
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
    DateTime periodStart,
    String cycleId,
    bool isIrregular,
    double stdDev,
  ) {
    final ovulationDate = periodStart.subtract(_ovulationDayBeforePeriod.days);
    final windowExtension = isIrregular
        ? (stdDev / _ovulationWindowExtensionDivisor)
              .clamp(0, _maxOvulationWindowExtension)
              .round()
        : 0;

    final fertileStart = ovulationDate.subtract(
      (_ovulationWindowStartOffset + windowExtension).days,
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
        flow: i < _heavyFlowDays ? FlowIntensity.medium : FlowIntensity.light,
        createdBy: 'system',
        ownedBy: 'system',
        users: [],
        isPrediction: true,
      );
    });
  }

  List<CycleLog> _getSortedActualPeriodLogs(List<CycleLog> logs) {
    return logs
        .where((l) => l.type == LogType.period && !l.isPrediction)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}

class _CycleData {
  const _CycleData({
    required this.avgCycleLength,
    required this.stdDev,
    required this.avgPeriodDays,
    required this.isIrregular,
    required this.nextPeriodStart,
    this.random,
  });

  final double avgCycleLength;
  final double stdDev;
  final int avgPeriodDays;
  final bool isIrregular;
  final DateTime nextPeriodStart;
  final Random? random;
}
