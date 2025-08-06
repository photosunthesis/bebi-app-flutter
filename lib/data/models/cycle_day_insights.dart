enum CyclePhase { period, follicular, ovulation, luteal }

class CycleDayInsights {
  const CycleDayInsights({
    required this.date,
    required this.cyclePhase,
    required this.typicalPeriodLengthInDays,
    required this.typicalCycleLengthInDays,
    required this.cyclePeriodDates,
    required this.cycleFertileDates,
    required this.summaryAndInsights,
    this.isPast = false,
  });

  final DateTime date;
  final CyclePhase cyclePhase;
  final int typicalPeriodLengthInDays;
  final int typicalCycleLengthInDays;
  final List<DateTime> cyclePeriodDates;
  final List<DateTime> cycleFertileDates;
  final String summaryAndInsights;
  final bool isPast;
}
