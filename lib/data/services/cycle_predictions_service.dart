import 'dart:math';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:injectable/injectable.dart';

@Injectable()
class CyclePredictionsService {
  const CyclePredictionsService();

  static const _maxPredictions = 6;
  static const _defaultCycleLength = 28;
  static const _maxCycleLengthDeviation = 14;

  List<CycleLog> predictUpcomingCycles(List<CycleLog> logs) {
    final now = DateTime.now();
    final rand = Random(now.millisecondsSinceEpoch);
    final periodLogs = _getSortedActualPeriodLogs(logs);

    if (periodLogs.length < 2) return [];

    final cycleGaps = _calculateCycleGaps(periodLogs);
    final avgCycleLength = _calculateAverageCycleLength(cycleGaps);
    final stdDev = _calculateStandardDeviation(cycleGaps);
    final isIrregular = stdDev > 4;

    var nextPeriodStart = periodLogs.last.date;

    final predictions = <CycleLog>[];

    for (var i = 0; i < _maxPredictions; i++) {
      final cycleId = 'predicted_cycle_$i';

      final deviation = isIrregular
          ? (rand.nextDouble() * 2 - 1) * min(stdDev, _maxCycleLengthDeviation)
          : 0;

      final cycleLength = (avgCycleLength + deviation).round();

      nextPeriodStart = nextPeriodStart.add(cycleLength.days);

      predictions.addAll(
        _generatePredictedPeriodLogs(
          start: nextPeriodStart,
          cycleId: cycleId,
          isIrregular: isIrregular,
          stdDev: stdDev,
        ),
      );

      predictions.addAll(
        _generatePredictedOvulationWindow(
          periodStart: nextPeriodStart,
          cycleId: cycleId,
          isIrregular: isIrregular,
          stdDev: stdDev,
        ),
      );
    }

    return predictions;
  }

  List<CycleLog> _getSortedActualPeriodLogs(List<CycleLog> logs) {
    return logs
        .where((l) => l.type == LogType.period && !l.isPrediction)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<int> _calculateCycleGaps(List<CycleLog> periodLogs) {
    final recentLogs = periodLogs.length > 12
        ? periodLogs.sublist(periodLogs.length - 12)
        : periodLogs;
    final gaps = <int>[];
    for (var i = 1; i < recentLogs.length; i++) {
      final diff = recentLogs[i].date.difference(recentLogs[i - 1].date).inDays;
      if (diff > 15 && diff < 45) gaps.add(diff);
    }
    return gaps;
  }

  int _calculateAverageCycleLength(List<int> gaps) {
    if (gaps.isEmpty) return _defaultCycleLength;
    return (gaps.reduce((a, b) => a + b) / gaps.length).round();
  }

  double _calculateStandardDeviation(List<int> gaps) {
    if (gaps.length < 2) return 0.0;

    final mean = gaps.reduce((a, b) => a + b) / gaps.length;
    final variance =
        gaps.map((g) => pow(g - mean, 2)).reduce((a, b) => a + b) /
        (gaps.length - 1);

    return sqrt(variance);
  }

  List<CycleLog> _generatePredictedOvulationWindow({
    required DateTime periodStart,
    required String cycleId,
    required bool isIrregular,
    required double stdDev,
  }) {
    final ovulationDate = periodStart.subtract(14.days);
    final windowExtension = isIrregular ? (stdDev / 2).clamp(0, 3).round() : 0;
    final fertileStart = ovulationDate.subtract((5 + windowExtension).days);
    final windowDays = 6 + windowExtension;

    return List.generate(windowDays, (i) {
      final date = fertileStart.add(i.days);
      return CycleLog.ovulation(
        id: '${cycleId}_ovulation_$i',
        date: date,
        createdBy: 'system',
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
    final periodDays = 4 + periodExtension;

    return List.generate(periodDays, (i) {
      final date = start.add(i.days);
      return CycleLog.period(
        id: '${cycleId}_period_$i',
        date: date,
        flow: i < 2 ? FlowIntensity.medium : FlowIntensity.light,
        createdBy: 'system',
        users: [],
        isPrediction: true,
      );
    });
  }
}
