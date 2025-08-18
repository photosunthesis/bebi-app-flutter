enum CyclePhase { period, follicular, ovulation, luteal }

class CycleDayInsights {
  const CycleDayInsights({
    required this.date,
    required this.cyclePhase,
    required this.dayOfCycle,
    required this.cycleLengthInDays,
    required this.averagePeriodDurationInDays,
    required this.nextPeriodDates,
    required this.fertileDays,
  });

  final DateTime date;
  final CyclePhase cyclePhase;
  final int dayOfCycle;
  final int cycleLengthInDays;
  final int averagePeriodDurationInDays;
  final List<DateTime> nextPeriodDates;
  final List<DateTime> fertileDays;
}
