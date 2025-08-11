import 'dart:async';

import 'package:bebi_app/data/models/cycle_day_insights.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
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

  static const _maxDaysBetweenPeriodEvents = 14;

  CycleDayInsights? getInsightsFromDateAndEvents(
    DateTime date,
    List<CycleLog> events,
  ) {
    final sortedEvents = events.sortedBy((e) => e.date);
    final periodEvents = sortedEvents.where((e) => e.type == LogType.period);
    final ovulationEvents = sortedEvents.where(
      (e) => e.type == LogType.ovulation,
    );

    final periodGroups = _groupEventsByProximity(periodEvents.toList());
    final cyclePeriodGroups = _findCurrentCyclePeriodGroups(date, periodGroups);

    if (cyclePeriodGroups == null) return null;

    final (currentPeriodDates, nextPeriodDates) = cyclePeriodGroups;
    final cycleStart = currentPeriodDates.first;
    final nextCycleStart = nextPeriodDates.first;

    final currentFertileWindow = _getCurrentFertileWindow(
      ovulationEvents.map((e) => e.date).toList(),
      cycleStart,
      nextCycleStart,
    );

    final dayOfCycle = date.noTime().difference(cycleStart.noTime()).inDays + 1;
    final cycleLengthInDays = nextCycleStart
        .noTime()
        .difference(cycleStart.noTime())
        .inDays;

    final cyclePhase = _getCyclePhase(
      date,
      currentPeriodDates,
      nextPeriodDates,
      currentFertileWindow,
    );

    return CycleDayInsights(
      cyclePhase: cyclePhase,
      date: date,
      dayOfCycle: dayOfCycle,
      cycleLengthInDays: cycleLengthInDays,
      nextPeriodDates: nextPeriodDates,
      fertileDays: currentFertileWindow,
    );
  }

  List<List<DateTime>> _groupEventsByProximity(List<CycleLog> events) {
    final groups = <List<CycleLog>>[];

    for (final event in events) {
      final group = groups.lastOrNull;
      if (group == null ||
          event.date.difference(group.last.date).inDays >
              _maxDaysBetweenPeriodEvents) {
        groups.add([event]);
      } else {
        group.add(event);
      }
    }

    return groups.map((e) => e.map((e) => e.dateLocal).toList()).toList();
  }

  (List<DateTime>, List<DateTime>)? _findCurrentCyclePeriodGroups(
    DateTime date,
    List<List<DateTime>> periodGroups,
  ) {
    if (periodGroups.length < 2) {
      return null;
    }

    for (var i = 0; i < periodGroups.length - 1; i++) {
      final currentPeriod = periodGroups[i];
      final nextPeriod = periodGroups[i + 1];

      if (currentPeriod.isEmpty || nextPeriod.isEmpty) {
        continue;
      }

      final cycleStart = currentPeriod.first;
      final nextCycleStart = nextPeriod.first;

      final isAfterOrOnCycleStart =
          date.isAfter(cycleStart) || date.isSameDay(cycleStart);

      if (isAfterOrOnCycleStart && date.isBefore(nextCycleStart)) {
        return (currentPeriod, nextPeriod);
      }
    }

    return null;
  }

  List<DateTime> _getCurrentFertileWindow(
    List<DateTime> ovulationDates,
    DateTime cycleStart,
    DateTime nextCycleStart,
  ) {
    if (ovulationDates.isEmpty) return [];
    return ovulationDates
        .where((e) => e.isBefore(nextCycleStart) && e.isAfter(cycleStart))
        .toList();
  }

  CyclePhase _getCyclePhase(
    DateTime date,
    List<DateTime> currentOrPastPeriodDates,
    List<DateTime> futurePeriodDates,
    List<DateTime> currentFertileWindow,
  ) {
    final isPeriod =
        currentOrPastPeriodDates.any((d) => d.isSameDay(date)) ||
        futurePeriodDates.any((d) => d.isSameDay(date));
    if (isPeriod) {
      return CyclePhase.period;
    }

    if (currentFertileWindow.any((d) => d.isSameDay(date))) {
      return CyclePhase.ovulation;
    }

    if (currentFertileWindow.isNotEmpty &&
        date.isAfter(currentOrPastPeriodDates.last) &&
        date.isBefore(currentFertileWindow.first)) {
      return CyclePhase.follicular;
    }

    return CyclePhase.luteal;
  }

  Future<String> generateAiInsights(
    CycleDayInsights cycleDayInsights, {
    required bool isCurrentUser,
  }) async {
    final date = cycleDayInsights.date.toIso8601String().substring(0, 10);
    final key = '${date}_${isCurrentUser ? 'self' : 'partner'}';
    final cachedInsights = _summaryAndInsightsBox.get(key);
    if (cachedInsights != null) return cachedInsights;

    final prompt = _generateInsightsPrompt(cycleDayInsights, isCurrentUser);

    final response = await _generativeModel.generateContent([
      Content.text(prompt),
    ]);

    final result =
        response.text ?? 'An error occurred while generating insights.';

    unawaited(_summaryAndInsightsBox.put(key, result));

    return result;
  }

  String _generateInsightsPrompt(
    CycleDayInsights insights,
    bool isCurrentUser,
  ) {
    final userContext = isCurrentUser
        ? '''
    This is about the user's own cycle.
    - Use "you" when referring to the person whose cycle this is.
    - Use "your" for possessive references.
    - Use "yourself" for reflexive references.
    '''
        : '''
    This is about the user's partner's cycle.
    - Use "your partner" when referring to the person whose cycle this is.
    - Use "your partner's" for possessive references.
    - Use "your partner" for reflexive references (e.g., "a treat for your partner").
    ''';

    return '''
    You are a medical professional providing personalized cycle insights directly to the app user. Your role is to deliver medically accurate, relatable advice with a professional, candid tone that addresses adult topics without awkwardness. Your response will be displayed directly in a mobile app interface.

    USER DATA:
    - Current cycle date: ${insights.date.toEEEEMMMMdyyyy()}
    - Day of cycle: ${insights.dayOfCycle}
    - Cycle length: ${insights.cycleLengthInDays}
    - Cycle Phase: ${insights.cyclePhase.name}
    - Predicted Period Dates: ${insights.nextPeriodDates.map((e) => e.toEEEEMMMMdyyyy()).join(', ')}
    - Predicted Fertile Dates: ${insights.fertileDays.map((e) => e.toEEEEMMMMdyyyy()).join(', ')}

    RESPONSE STRUCTURE REQUIREMENTS:
    1. Start with exactly ONE engaging introductory sentence about the current cycle day
    2. Follow with exactly THREE bullet points using markdown format
    3. Each bullet point must be 25-35 words maximum
    4. No additional text, explanations, or meta-commentary outside this format
    5. Write as if speaking directly to the user
    6. The output must be in markdown syntax for proper display in the mobile app
    7. Emphasize key information using **bold** markdown sparingly and meaningfully in bullet points

    TONE AND CONTENT GUIDELINES:
    - Write like a wise and kind doctor, giving advice to a friend
    - Be medically accurate but conversational and relatable
    - Address adult topics (sex, fertility, periods, contraception) with candid humor
    - Use zero euphemisms - be direct but tasteful
    - Include practical, actionable advice
    - Acknowledge real struggles (cramps, mood swings, bloating, PMS)
    - Be empathetic about menstrual experiences

    CRITICAL FERTILITY/OVULATION INSTRUCTIONS:
    - Prioritize contraception advice over conception advice, so lead with protection reminders first
    - Only mention conception as a secondary, optional consideration

    PHASE-SPECIFIC GUIDANCE:
    - Follicular: Energy building, skin clearing, mood lifting
    - Ovulation: Peak fertility = protection priority, libido changes, energy peaks
    - Luteal: PMS prep, mood changes, comfort needs, bloating, cravings
    - Period: Pain management, comfort measures, energy conservation

    CONTEXT FOR YOUR RESPONSE:
    $userContext

    EXAMPLE FORMAT:
    [A natural, conversational opening sentence indicating what the current cycle phase is and all the things it may come with, symptoms, and energy levels. - no bullet point] 

    - [First insight - 25-35 words, actionable advice]
    - [Second insight - 25-35 words, symptom awareness or preparation]
    - [Third insight - 25-35 words, practical tip or encouragement, or a witty joke]

    Generate insights about what might happen or might have happened on this specific cycle day based on the phase and predictions. Be specific to the cycle timing and phase-appropriate symptoms or experiences.
    ''';
  }
}
