import 'dart:math';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

@injectable
class CyclePredictionsService {
  const CyclePredictionsService();

  static const _maxPredictions = 6;
  static const _defaultCycleLength = 28;
  static const _maxCycleLengthDeviation = 14.0;
  static const _maxHistoricalCycles = 12;
  static const _minCycleGap = 15;
  static const _maxCycleGap = 45;
  static const _irregularityThreshold = 4.0;
  static const _ovulationDayBeforePeriod = 14;
  static const _baseFertileWindowDays = 6;
  static const _basePeriodDays = 4;

  List<CycleLog> predictUpcomingCycles(List<CycleLog> logs, DateTime now) {
    final periodLogs = _getSortedActualPeriodLogs(logs);
    if (periodLogs.length < 2) return [];

    final cycleStats = _calculateCycleStatistics(periodLogs);
    final isIrregular = cycleStats.stdDev > _irregularityThreshold;
    final rand = isIrregular ? Random(now.millisecondsSinceEpoch) : null;

    var nextPeriodStart = _adjustNextPeriodForSymptoms(
      logs,
      periodLogs.last.date,
      now,
    );

    final predictions = <CycleLog>[];
    for (var i = 0; i < _maxPredictions; i++) {
      final cycleId = 'predicted_cycle_$i';
      final cycleLength = _getPredictedCycleLength(
        avgCycleLength: cycleStats.avg,
        stdDev: cycleStats.stdDev,
        isIrregular: isIrregular,
        rand: rand,
      );

      nextPeriodStart = nextPeriodStart.add(cycleLength.days);

      predictions.addAll(
        _generatePredictedPeriodLogs(
          start: nextPeriodStart,
          cycleId: cycleId,
          isIrregular: isIrregular,
          stdDev: cycleStats.stdDev,
        ),
      );

      predictions.addAll(
        _generatePredictedOvulationWindow(
          periodStart: nextPeriodStart,
          cycleId: cycleId,
          isIrregular: isIrregular,
          stdDev: cycleStats.stdDev,
        ),
      );
    }

    return predictions;
  }

  ({double avg, double stdDev}) _calculateCycleStatistics(
    List<CycleLog> periodLogs,
  ) {
    final periodStartDates = _extractPeriodStartDates(periodLogs);
    if (periodStartDates.length < 2) {
      return (avg: _defaultCycleLength.toDouble(), stdDev: 0.0);
    }

    final recentStartDates = periodStartDates.length > _maxHistoricalCycles
        ? periodStartDates.sublist(
            periodStartDates.length - _maxHistoricalCycles,
          )
        : periodStartDates;

    final gaps = <int>[];
    for (var i = 1; i < recentStartDates.length; i++) {
      final diff = recentStartDates[i]
          .difference(recentStartDates[i - 1])
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

  double _calculateStandardDeviation(List<int> gaps, double mean) {
    final variance = gaps.map((g) => pow(g - mean, 2)).sum / (gaps.length - 1);
    return sqrt(variance);
  }

  List<DateTime> _extractPeriodStartDates(List<CycleLog> periodLogs) {
    if (periodLogs.isEmpty) return [];

    final startDates = <DateTime>[periodLogs.first.date];
    for (var i = 1; i < periodLogs.length; i++) {
      if (periodLogs[i].date.difference(periodLogs[i - 1].date).inDays > 1) {
        startDates.add(periodLogs[i].date);
      }
    }
    return startDates;
  }

  DateTime _adjustNextPeriodForSymptoms(
    List<CycleLog> allLogs,
    DateTime lastPeriodDate,
    DateTime now,
  ) {
    final hasRecentCramps = allLogs.any((log) {
      final daysSinceLog = now.difference(log.date).inDays;
      return daysSinceLog <= 7 &&
          log.type == LogType.symptom &&
          !log.isPrediction &&
          log.symptoms?.contains('cramps') == true;
    });

    return hasRecentCramps ? lastPeriodDate.subtract(1.days) : lastPeriodDate;
  }

  int _getPredictedCycleLength({
    required double avgCycleLength,
    required double stdDev,
    required bool isIrregular,
    Random? rand,
  }) {
    if (!isIrregular) return avgCycleLength.round();

    final deviation =
        (rand!.nextDouble() * 2 - 1) * min(stdDev, _maxCycleLengthDeviation);
    return (avgCycleLength + deviation).round();
  }

  List<CycleLog> _generatePredictedOvulationWindow({
    required DateTime periodStart,
    required String cycleId,
    required bool isIrregular,
    required double stdDev,
  }) {
    final ovulationDate = periodStart.subtract(_ovulationDayBeforePeriod.days);
    final windowExtension = isIrregular ? (stdDev / 2).clamp(0, 3).round() : 0;
    final fertileStart = ovulationDate.subtract((5 + windowExtension).days);
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

  List<CycleLog> _generatePredictedPeriodLogs({
    required DateTime start,
    required String cycleId,
    required bool isIrregular,
    required double stdDev,
  }) {
    final periodExtension = isIrregular ? (stdDev / 4).clamp(0, 2).round() : 0;
    final periodDays = _basePeriodDays + periodExtension;

    return List.generate(periodDays, (i) {
      final date = start.add(i.days);
      return CycleLog.period(
        id: '${cycleId}_period_$i',
        date: date,
        flow: i < 2 ? FlowIntensity.medium : FlowIntensity.light,
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
