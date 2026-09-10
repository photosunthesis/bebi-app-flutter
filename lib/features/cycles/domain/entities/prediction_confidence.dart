enum PredictionTrend { stable, lengthening, shortening }

enum PredictionConfidenceLevel {
  low,
  medium,
  high;

  String get label => name[0].toUpperCase() + name.substring(1);
}

class PredictionConfidence {
  const PredictionConfidence({
    required this.accuracy,
    required this.cyclesAnalyzed,
    required this.hasSymptomData,
    required this.trend,
  });

  final double accuracy; // 0.0 to 1.0
  final int cyclesAnalyzed;
  final bool hasSymptomData;
  final PredictionTrend trend;

  PredictionConfidenceLevel get level {
    if (accuracy >= 0.8) return PredictionConfidenceLevel.high;
    if (accuracy >= 0.5) return PredictionConfidenceLevel.medium;
    return PredictionConfidenceLevel.low;
  }
}
