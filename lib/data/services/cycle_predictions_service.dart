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
  static const _minCycleGap = 15;
  static const _maxCycleGap = 45;
  static const _irregularityThreshold = 4.0;
  static const _ovulationDayBeforePeriod = 14;
  static const _baseFertileWindowDays = 6;

  List<CycleLog> predictUpcomingCycles(List<CycleLog> logs, DateTime now) {
    final periodLogs = _getSortedActualPeriodLogs(logs);
    if (periodLogs.length < 2) return [];

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
    final nextPeriodStart = _adjustNextPeriodForSymptoms(
      allLogs,
      periodLogs.last.date,
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
    if (periodStartDates.isEmpty) return 4;

    final cyclePeriodDays = <int>[];
    for (final startDate in periodStartDates) {
      final cycleEndDate = _findCycleEndDateOptimized(periodLogs, startDate);
      if (cycleEndDate != null) {
        final periodDays = cycleEndDate.difference(startDate).inDays + 1;
        cyclePeriodDays.add(periodDays);
      }
    }

    if (cyclePeriodDays.isEmpty) return 4;

    final avgDays = cyclePeriodDays.average;
    return avgDays.round().clamp(3, 7);
  }

  DateTime? _findCycleEndDateOptimized(
    List<CycleLog> periodLogs,
    DateTime startDate,
  ) {
    DateTime? lastConsecutiveDate;
    var foundStart = false;

    for (final log in periodLogs) {
      if (!foundStart) {
        if (log.date.isAtSameMomentAs(startDate)) {
          foundStart = true;
          lastConsecutiveDate = log.date;
        }
        continue;
      }

      if (log.date.difference(lastConsecutiveDate!).inDays == 1) {
        lastConsecutiveDate = log.date;
      } else {
        break;
      }
    }

    return lastConsecutiveDate;
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
    final cutoffDate = now.subtract(7.days);

    final hasRecentCramps = allLogs.any(
      (log) =>
          log.date.isAfter(cutoffDate) &&
          log.type == LogType.symptom &&
          !log.isPrediction &&
          log.symptoms?.contains('cramps') == true,
    );

    return hasRecentCramps ? lastPeriodDate.subtract(1.days) : lastPeriodDate;
  }

  int _getPredictedCycleLength(
    double avgCycleLength,
    double stdDev,
    bool isIrregular,
    Random? rand,
  ) {
    if (!isIrregular) return avgCycleLength.round();

    final deviation =
        (rand!.nextDouble() * 2 - 1) * min(stdDev, _maxCycleLengthDeviation);
    return (avgCycleLength + deviation).round();
  }

  List<CycleLog> _generatePredictedOvulationWindow(
    DateTime periodStart,
    String cycleId,
    bool isIrregular,
    double stdDev,
  ) {
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

  List<CycleLog> _generatePredictedPeriodLogs(
    DateTime start,
    String cycleId,
    int avgPeriodDays,
    bool isIrregular,
    double stdDev,
  ) {
    final periodExtension = isIrregular ? (stdDev / 4).clamp(0, 2).round() : 0;
    final periodDays = avgPeriodDays + periodExtension;

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
