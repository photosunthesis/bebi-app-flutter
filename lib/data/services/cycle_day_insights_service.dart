import 'package:bebi_app/data/models/cycle_day_insights.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@Injectable()
class CycleDayInsightsService {
  const CycleDayInsightsService(
    this._generativeModel,
    this._summaryAndInsightsBox,
  );

  final GenerativeModel _generativeModel;
  final Box<String> _summaryAndInsightsBox;

  Future<CycleDayInsights> getInsightsFromDateAndEvents(
    DateTime date,
    List<CycleLog> events,
  ) async {
    final dateKey = date.toIso8601String().substring(0, 10);
    final cachedInsights = _summaryAndInsightsBox.get(dateKey);
    final periodEvents = events.where((e) => e.type == LogType.period).toList();
    final typicalPeriodLength = _calculateAveragePeriodLength(periodEvents);
    final typicalCycleLength = _calculateAverageCycleLength(periodEvents);
    final cyclePeriodDates = _calculatePeriodDates(
      periodEvents,
      date,
      typicalPeriodLength,
    );
    final cycleFertileDates = _calculateFertileDates(
      cyclePeriodDates,
      typicalCycleLength,
    );
    final cyclePhase = _getCyclePhase(
      date,
      cyclePeriodDates,
      cycleFertileDates,
    );

    if (cachedInsights != null) {
      return CycleDayInsights(
        cyclePhase: cyclePhase,
        date: date,
        isPast: date.isBefore(DateTime.now()),
        typicalPeriodLengthInDays: typicalPeriodLength,
        typicalCycleLengthInDays: typicalCycleLength,
        cyclePeriodDates: cyclePeriodDates.map((e) => e.dateLocal).toList(),
        cycleFertileDates: cycleFertileDates.map((e) => e.dateLocal).toList(),
        summaryAndInsights: cachedInsights,
      );
    }

    final summaryAndInsights = await _generateAiInsights(
      date: date,
      cyclePhase: cyclePhase,
      isPast: date.isBefore(DateTime.now()),
      typicalPeriodLengthInDays: typicalPeriodLength,
      typicalCycleLengthInDays: typicalCycleLength,
      predictedPeriodDates: cyclePeriodDates,
      predictedFertileDates: cycleFertileDates,
    );

    await _summaryAndInsightsBox.put(dateKey, summaryAndInsights);

    return CycleDayInsights(
      cyclePhase: cyclePhase,
      date: date,
      isPast: date.isBefore(DateTime.now()),
      typicalPeriodLengthInDays: typicalPeriodLength,
      typicalCycleLengthInDays: typicalCycleLength,
      cyclePeriodDates: cyclePeriodDates.map((e) => e.dateLocal).toList(),
      cycleFertileDates: cycleFertileDates.map((e) => e.dateLocal).toList(),
      summaryAndInsights: summaryAndInsights,
    );
  }

  List<CycleLog> _calculatePeriodDates(
    List<CycleLog> periodEvents,
    DateTime referenceDate,
    int typicalPeriodLength,
  ) {
    if (periodEvents.isEmpty) return [];

    // This is a simplified logic. A real implementation would be more complex.
    final closestPeriodEvent = periodEvents.reduce(
      (a, b) =>
          a.date.difference(referenceDate).abs() <
              b.date.difference(referenceDate).abs()
          ? a
          : b,
    );

    final startDate = closestPeriodEvent.date;
    return List.generate(
      typicalPeriodLength,
      (index) => closestPeriodEvent.copyWith(
        date: startDate.add(Duration(days: index)),
      ),
    );
  }

  List<CycleLog> _calculateFertileDates(
    List<CycleLog> periodDates,
    int typicalCycleLength,
  ) {
    if (periodDates.isEmpty) return [];

    final periodStartDate = periodDates.first.date;
    // Ovulation is roughly in the middle of the cycle.
    final ovulationDay = periodStartDate.add(
      Duration(days: typicalCycleLength ~/ 2),
    );
    // Fertile window is typically 5 days before ovulation and the day of.
    final fertileStartDate = ovulationDay.subtract(const Duration(days: 5));
    return List.generate(
      6,
      (index) => periodDates.first.copyWith(
        date: fertileStartDate.add(Duration(days: index)),
      ),
    );
  }

  CyclePhase _getCyclePhase(
    DateTime date,
    List<CycleLog> periodDates,
    List<CycleLog> fertileDates,
  ) {
    if (periodDates.any((e) => e.dateLocal.isAtSameMomentAs(date))) {
      return CyclePhase.period;
    }

    if (fertileDates.any((e) => e.dateLocal.isAtSameMomentAs(date))) {
      return CyclePhase.ovulation;
    }

    if (periodDates.isNotEmpty && date.isBefore(periodDates.first.dateLocal)) {
      return CyclePhase.luteal;
    }

    return CyclePhase.follicular;
  }

  int _calculateAveragePeriodLength(List<CycleLog> periodEvents) {
    if (periodEvents.length < 2) return 5;

    periodEvents.sort((a, b) => a.dateLocal.compareTo(b.dateLocal));

    final periodLengths = <int>[];
    var currentPeriodLength = 1;

    for (var i = 1; i < periodEvents.length; i++) {
      final difference = periodEvents[i].dateLocal
          .difference(periodEvents[i - 1].dateLocal)
          .inDays;
      if (difference == 1) {
        currentPeriodLength++;
      } else {
        periodLengths.add(currentPeriodLength);
        currentPeriodLength = 1;
      }
    }
    periodLengths.add(currentPeriodLength);

    if (periodLengths.isEmpty) return 5;

    return (periodLengths.reduce((a, b) => a + b) / periodLengths.length)
        .round();
  }

  int _calculateAverageCycleLength(List<CycleLog> periodEvents) {
    if (periodEvents.length < 2) return 28;

    periodEvents.sort((a, b) => a.date.compareTo(b.date));

    final periodStartDates = <DateTime>[periodEvents.first.dateLocal];
    for (var i = 1; i < periodEvents.length; i++) {
      final difference = periodEvents[i].dateLocal
          .difference(periodEvents[i - 1].dateLocal)
          .inDays;
      if (difference > 1) {
        periodStartDates.add(periodEvents[i].dateLocal);
      }
    }

    if (periodStartDates.length < 2) return 28;

    final cycleLengths = <int>[];
    for (var i = 1; i < periodStartDates.length; i++) {
      final cycleLength = periodStartDates[i]
          .difference(periodStartDates[i - 1])
          .inDays;
      cycleLengths.add(cycleLength);
    }

    if (cycleLengths.isEmpty) return 28;

    return (cycleLengths.reduce((a, b) => a + b) / cycleLengths.length).round();
  }

  Future<String> _generateAiInsights({
    required DateTime date,
    required CyclePhase cyclePhase,
    required bool isPast,
    required int typicalPeriodLengthInDays,
    required int typicalCycleLengthInDays,
    required List<CycleLog> predictedPeriodDates,
    required List<CycleLog> predictedFertileDates,
  }) async {
    final prompt =
        '''
    You are a friendly and chill virtual cycle assistant for adults. Provide 2-3 bullet points of advice and insights for the user's cycle day.
    Keep the tone light, reassuring, playful, and easy to understand. Don't be shy about mentioning intimacy, sexy time, fertility windows, symptoms, and the real struggles of periods and PMS - we're all adults here and we know the luteal phase can suck ass!

    Here's the user's data:
    - Date: ${date.toIso8601String()}
    - Cycle Phase: ${cyclePhase.name}
    - Day is in the: ${isPast ? 'past' : 'future'}
    - Typical Period Length: $typicalPeriodLengthInDays days
    - Typical Cycle Length: $typicalCycleLengthInDays days
    - Predicted Period Dates: ${predictedPeriodDates.map((e) => e.dateLocal.toIso8601String()).join(', ')}
    - Predicted Fertile Dates: ${predictedFertileDates.map((e) => e.dateLocal.toIso8601String()).join(', ')}

    Generate a response with 2-3 bullet points of advice. Be relatable about period struggles, PMS symptoms, luteal phase mood swings, cramps, bloating, and all the fun stuff. Feel free to mention sexy time, freaky time, fertility windows, and intimacy when relevant. For example:
    "- You're in the luteal phase, which honestly can be rough with mood changes and irritability - totally normal! Consider prioritizing self-care and maybe keeping some comfort snacks handy.
    - Your period is approaching, and it's not fun. Consider preparing with a heating pad, comfortable clothes, and whatever comfort measures work best for you.
    - You're in your fertile window right now - perfect timing for intimacy if you're trying to conceive, or make sure you're using reliable contraception if pregnancy isn't your goal!"
    ''';

    final response = await _generativeModel.generateContent([
      Content.text(prompt),
    ]);

    return response.text ?? 'An error occured while generating insights.';
  }
}
