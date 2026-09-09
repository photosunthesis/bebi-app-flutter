import 'dart:math';

import 'package:bebi_app/features/cycles/domain/cycle_log.dart';
import 'package:bebi_app/features/cycles/domain/prediction_confidence.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

@injectable
class CyclePredictionsService with LocalizationsMixin {
  const CyclePredictionsService();

  static const _defaultCycleLength = 28;
  static const _minCycleGap = 15;
  static const _maxCycleGap = 45;
  static const _irregularityThreshold = 4.0;
  static const _defaultOvulationDayBeforePeriod = 14;
  static const _baseFertileWindowDays = 6;
  static const _defaultPeriodLength = 4;
  static const _minPeriodDays = 1;
  static const _maxPeriodDays = 10;
  static const _consecutiveDayThreshold = 14;
  static const _ovulationWindowExtensionDivisor = 2;
  static const _maxOvulationWindowExtension = 3;
  static const _periodExtensionDivisor = 4;
  static const _maxPeriodExtension = 2;

  // Symptom-based prediction weights (days before period)
  static const _symptomOffsets = {
    'cramps': 2,
    'breast_tenderness': 4, // 3-5 days
    'mood_swings': 3, // 2-4 days
    'bloating': 3, // 2-3 days
    'headache': 2, // 1-3 days
    'fatigue': 3, // 2-4 days
    'acne': 3, // 2-4 days
    'backache': 2, // 1-3 days
  };

  ({List<CycleLog> predictions, PredictionConfidence confidence})
  predictUpcomingCycles(List<CycleLog> logs, DateTime now) {
    if (logs.isEmpty) {
      return (
        predictions: <CycleLog>[],
        confidence: const PredictionConfidence(
          accuracy: 0,
          cyclesAnalyzed: 0,
          hasSymptomData: false,
          trend: PredictionTrend.stable,
        ),
      );
    }

    final periodLogs = _getSortedActualPeriodLogs(logs);
    if (periodLogs.isEmpty) throw ArgumentError(l10n.noPeriodDataError);

    final periodGroups = _groupPeriodEventsByProximity(periodLogs);
    if (periodGroups.isEmpty) throw ArgumentError(l10n.noPeriodDataError);

    final periodStartDates = _extractPeriodStartDates(periodGroups);
    final cycleLengths = _calculateCycleLengths(periodStartDates);
    final weightedAvgCycleLength = _calculateWeightedCycleLength(cycleLengths);
    final stdDev = _calculateStandardDeviationFromLengths(
      cycleLengths,
      weightedAvgCycleLength,
    );
    final avgPeriodDays = _calculateAveragePeriodDaysFromGroups(periodGroups);

    final isIrregular = stdDev > _irregularityThreshold;
    final lastPeriodDate = periodLogs.last.date;
    final baseNextPeriodStart = lastPeriodDate;

    // Check symptoms for adjustment
    final (adjustedDate, hasSymptomData) = _adjustNextPeriodForSymptoms(
      logs,
      baseNextPeriodStart,
      now,
    );

    var nextPeriodStart = adjustedDate;

    // Calculate confidence
    final trend = _detectCycleTrend(cycleLengths);
    final confidence = _calculateConfidence(
      cycleLengths.length,
      stdDev,
      hasSymptomData,
      trend,
    );

    final predictions = <CycleLog>[];

    // Calculate individual luteal phase
    // We need historical ovulation data to calculate this accurately
    // For now we will use a more sophisticated estimation based on cycle length if available
    final lutealPhaseLength = _estimateLutealPhaseLength(
      logs,
      periodStartDates,
    );

    final historicalOvulations = _generateHistoricalOvulationPredictions(
      periodGroups,
      lutealPhaseLength,
    );
    predictions.addAll(historicalOvulations);

    for (var i = 0; i < 6; i++) {
      final cycleId = 'predicted_cycle_$i';

      // Use weighted average without random variation for future predictions
      // This is more reliable for user planning than random noise
      final currentCycleLength = weightedAvgCycleLength.round();

      nextPeriodStart = nextPeriodStart.add(currentCycleLength.days);

      predictions.addAll(
        _generatePredictedPeriodLogs(
          nextPeriodStart,
          cycleId,
          avgPeriodDays,
          isIrregular,
          stdDev,
          logs, // Pass all logs to analyze flow patterns
        ),
      );

      predictions.addAll(
        _generatePredictedOvulationWindow(
          nextPeriodStart,
          lutealPhaseLength,
          cycleId,
          isIrregular,
          stdDev,
        ),
      );
    }

    return (predictions: predictions, confidence: confidence);
  }

  PredictionConfidence _calculateConfidence(
    int cyclesAnalyzed,
    double stdDev,
    bool hasSymptomData,
    PredictionTrend trend,
  ) {
    // Base accuracy starts low
    var accuracy = 0.3;

    // More cycles = better accuracy
    if (cyclesAnalyzed >= 6) {
      accuracy += 0.4;
    } else if (cyclesAnalyzed >= 3) {
      accuracy += 0.2;
    }

    // Regular cycles = better accuracy
    if (stdDev < 2.0) {
      accuracy += 0.2;
    } else if (stdDev < 4.0) {
      accuracy += 0.1;
    }

    // Symptom matches increase confidence for near-term prediction
    if (hasSymptomData) {
      accuracy += 0.1;
    }

    // Unstable trend reduces confidence slightly
    if (trend != PredictionTrend.stable) {
      accuracy -= 0.1;
    }

    return PredictionConfidence(
      accuracy: accuracy.clamp(0.0, 1.0),
      cyclesAnalyzed: cyclesAnalyzed,
      hasSymptomData: hasSymptomData,
      trend: trend,
    );
  }

  PredictionTrend _detectCycleTrend(List<int> cycleLengths) {
    if (cycleLengths.length < 3) return PredictionTrend.stable;

    final half = cycleLengths.length ~/ 2;
    final firstHalfAvg = cycleLengths.take(half).average;
    final secondHalfAvg = cycleLengths.skip(half).average;

    final diff = secondHalfAvg - firstHalfAvg;

    if (diff > 2) return PredictionTrend.lengthening;
    if (diff < -2) return PredictionTrend.shortening;
    return PredictionTrend.stable;
  }

  List<int> _calculateCycleLengths(List<DateTime> periodStartDates) {
    if (periodStartDates.length < 2) return [];

    final gaps = <int>[];
    for (var i = 1; i < periodStartDates.length; i++) {
      final diff = periodStartDates[i]
          .difference(periodStartDates[i - 1])
          .inDays;
      if (diff >= _minCycleGap && diff <= _maxCycleGap) {
        gaps.add(diff);
      }
    }
    return gaps;
  }

  double _calculateWeightedCycleLength(List<int> cycleLengths) {
    if (cycleLengths.isEmpty) return _defaultCycleLength.toDouble();
    if (cycleLengths.length == 1) return cycleLengths.first.toDouble();

    var totalWeight = 0.0;
    var weightedSum = 0.0;

    for (var i = 0; i < cycleLengths.length; i++) {
      // Recent cycles have higher weight
      // e.g. for 3 cycles: weights are 1, 2, 3
      final weight = (i + 1).toDouble();
      weightedSum += cycleLengths[i] * weight;
      totalWeight += weight;
    }

    return weightedSum / totalWeight;
  }

  double _calculateStandardDeviationFromLengths(List<int> gaps, double mean) {
    if (gaps.isEmpty || gaps.length < 2) return 0.0;
    return _calculateStandardDeviation(gaps, mean);
  }

  int _calculateAveragePeriodDaysFromGroups(List<List<CycleLog>> periodGroups) {
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

  List<DateTime> _extractPeriodStartDates(List<List<CycleLog>> periodGroups) {
    if (periodGroups.isEmpty) {
      throw ArgumentError(l10n.noPeriodDataError);
    }

    return periodGroups.map((group) => group.first.date).toList();
  }

  (DateTime, bool) _adjustNextPeriodForSymptoms(
    List<CycleLog> allLogs,
    DateTime lastPeriodDate,
    DateTime now,
  ) {
    final cutoffDate = now.subtract(
      7.days,
    ); // look back 7 days for recent symptoms

    // Get recent symptoms excluding predictions
    final recentSymptoms = allLogs
        .where(
          (log) =>
              log.date.isAfter(cutoffDate) &&
              log.type == LogType.symptom &&
              !log.isPrediction &&
              log.symptoms != null,
        )
        .expand((log) => log.symptoms!)
        .toSet();

    if (recentSymptoms.isEmpty) {
      return (lastPeriodDate, false);
    }

    // Find the symptom that predicts the earliest period onset (largest offset)
    var maxOffset = 0;
    var hasPredictiveSymptoms = false;

    for (final symptom in recentSymptoms) {
      if (_symptomOffsets.containsKey(symptom)) {
        final offset = _symptomOffsets[symptom]!;
        if (offset > maxOffset) {
          maxOffset = offset;
          hasPredictiveSymptoms = true;
        }
      }
    }

    // Only adjust if we have strong signal
    final adjustedDate = hasPredictiveSymptoms
        ? lastPeriodDate.subtract(1.days) // conservative 1 day adjustment
        : lastPeriodDate;

    if (adjustedDate.isBefore(now.subtract(60.days))) {
      // prevent predictions more than 60 days in the past
      return (lastPeriodDate, false);
    }

    return (adjustedDate, hasPredictiveSymptoms);
  }

  int _estimateLutealPhaseLength(
    List<CycleLog> logs,
    List<DateTime> periodStartDates,
  ) {
    // Try to calculate from historical data
    final ovulationLogs = logs
        .where((l) => l.type == LogType.ovulation && !l.isPrediction)
        .toList();

    if (ovulationLogs.isNotEmpty && periodStartDates.length >= 2) {
      final lutealLengths = <int>[];

      for (final ovulation in ovulationLogs) {
        // Find the period that started immediately after this ovulation
        final nextPeriod = periodStartDates
            .where((p) => p.isAfter(ovulation.date))
            .sortedBy((d) => d)
            .firstOrNull;

        if (nextPeriod != null) {
          final length = nextPeriod.difference(ovulation.date).inDays;
          if (length >= 10 && length <= 16) {
            lutealLengths.add(length);
          }
        }
      }

      if (lutealLengths.isNotEmpty) {
        return lutealLengths.average.round();
      }
    }

    // Fallback: Estimate based on total cycle length if it's very short or long
    // Standard text book is 14 days, but shorter cycles often have shorter luteal phases
    return _defaultOvulationDayBeforePeriod;
  }

  List<CycleLog> _generatePredictedOvulationWindow(
    DateTime nextPeriodStart,
    int lutealPhaseLength,
    String cycleId,
    bool isIrregular,
    double stdDev,
  ) {
    // Calculate ovulation by subtracting luteal phase from next period start
    // This assumes the luteal phase is relatively constant
    final ovulationDate = nextPeriodStart.subtract(lutealPhaseLength.days);

    final windowExtension = isIrregular
        ? (stdDev / _ovulationWindowExtensionDivisor)
              .clamp(0, _maxOvulationWindowExtension)
              .round()
        : 0;

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
    List<CycleLog> allLogs,
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

    // Analyze flow pattern for better predictions
    final flowPattern = _analyzeFlowPattern(allLogs, periodDays);

    return List.generate(periodDays, (i) {
      final date = start.add(i.days);

      // Use historical pattern if available, otherwise default logic
      FlowIntensity flow;
      if (i < flowPattern.length) {
        flow = flowPattern[i];
      } else {
        flow = i < 2 ? FlowIntensity.medium : FlowIntensity.light;
      }

      return CycleLog.period(
        id: '${cycleId}_period_$i',
        date: date,
        flow: flow,
        createdBy: 'system',
        ownedBy: 'system',
        users: [],
        isPrediction: true,
      );
    });
  }

  List<FlowIntensity> _analyzeFlowPattern(
    List<CycleLog> logs,
    int predictedDays,
  ) {
    // Get recent complete periods
    final periodGroups = _groupPeriodEventsByProximity(
      logs.where((l) => l.type == LogType.period && !l.isPrediction).toList(),
    );

    if (periodGroups.isEmpty) return [];

    // Take up to 3 most recent periods
    final recentPeriods = periodGroups.reversed.take(3).toList();
    final flowSums = List<int>.filled(10, 0); // Max 10 days
    final flowCounts = List<int>.filled(10, 0);

    for (final group in recentPeriods) {
      final sortedGroup = group.sortedBy((l) => l.date);
      for (var i = 0; i < sortedGroup.length; i++) {
        if (i < 10 && sortedGroup[i].flow != null) {
          flowSums[i] += sortedGroup[i].flow!.index;
          flowCounts[i]++;
        }
      }
    }

    final pattern = <FlowIntensity>[];
    for (var i = 0; i < predictedDays; i++) {
      if (i < 10 && flowCounts[i] > 0) {
        final avgFlowIndex = (flowSums[i] / flowCounts[i]).round();
        pattern.add(
          FlowIntensity.values[avgFlowIndex.clamp(
            0,
            FlowIntensity.values.length - 1,
          )],
        );
      } else {
        // Fallback
        pattern.add(i < 2 ? FlowIntensity.medium : FlowIntensity.light);
      }
    }

    return pattern;
  }

  List<CycleLog> _generateHistoricalOvulationPredictions(
    List<List<CycleLog>> periodGroups,
    int lutealPhaseLength,
  ) {
    if (periodGroups.length < 2) return [];

    final historicalOvulations = <CycleLog>[];

    for (var i = 0; i < periodGroups.length - 1; i++) {
      final currentPeriodGroup = periodGroups[i];
      final nextPeriodGroup = periodGroups[i + 1];

      final currentPeriodStart = currentPeriodGroup.first.date;
      final nextPeriodStart = nextPeriodGroup.first.date;

      final cycleLength = nextPeriodStart.difference(currentPeriodStart).inDays;

      if (cycleLength >= _minCycleGap && cycleLength <= _maxCycleGap) {
        // Calculate historical ovulation date by subtracting luteal phase from next period start
        final ovulationDate = nextPeriodStart.subtract(lutealPhaseLength.days);

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
