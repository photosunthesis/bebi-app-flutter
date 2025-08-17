import 'dart:async';

import 'package:bebi_app/data/models/cycle_day_insights.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@injectable
class CycleDayInsightsService {
  const CycleDayInsightsService(this._generativeModel, this._aiInsightsBox);

  final GenerativeModel _generativeModel;
  final Box<String> _aiInsightsBox;

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
      // 14 days is the max distance between two period events
      if (group == null || event.date.difference(group.last.date).inDays > 14) {
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
    required String locale,
  }) async {
    final date = cycleDayInsights.date.toIso8601String().substring(0, 10);
    final key = '${date}_${isCurrentUser ? 'self' : 'partner'}';
    final cachedInsights = _aiInsightsBox.get(key);
    if (cachedInsights != null) return cachedInsights;

    final prompt = _generateInsightsPrompt(
      cycleDayInsights,
      isCurrentUser,
      locale,
    );

    final response = await _generativeModel.generateContent([
      Content.text(prompt),
    ]);

    final result =
        response.text ?? 'An error occurred while generating insights.';

    unawaited(_aiInsightsBox.put(key, result));

    return result;
  }

  String _generateInsightsPrompt(
    CycleDayInsights insights,
    bool isCurrentUser,
    String locale,
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
    You are a health and wellness expert providing evidence-based cycle insights. Your role is to deliver medically accurate, practical guidance with professional empathy, subtle humor, and adult candor. Your response will be displayed directly in a mobile app interface.

    USER DATA:
    - Current cycle date: ${insights.date.toEEEEMMMMdyyyy()}
    - Day of cycle: ${insights.dayOfCycle}
    - Cycle length: ${insights.cycleLengthInDays}
    - Cycle Phase: ${insights.cyclePhase.name}
    - Predicted Period Dates: ${insights.nextPeriodDates.map((e) => e.toEEEEMMMMdyyyy()).join(', ')}
    - Predicted Fertile Dates: ${insights.fertileDays.map((e) => e.toEEEEMMMMdyyyy()).join(', ')}
    - 
    
    LANGUAGE: 
    - The response should be in the specified locale with culturally appropriate references
    - Locale: "${locale.toUpperCase()}"

    RESPONSE STRUCTURE REQUIREMENTS:
    1. Start with exactly ONE informative opening sentence about the current cycle phase or day (no greetings like "hello", "hi", "good day")
    2. Follow with exactly THREE bullet points using markdown format
    3. Each bullet point must be 25-35 words maximum
    4. No additional text, explanations, or meta-commentary outside this format
    5. Write as if speaking directly to the user
    6. The output must be in markdown syntax for proper display in the mobile app
    7. Emphasize key information using **bold** markdown sparingly and meaningfully

    TONE AND CONTENT GUIDELINES:
    - Professional health and wellness approach with empathetic understanding
    - Be medically accurate with practical, actionable insights
    - Address adult topics (sexuality, fertility, periods, contraception) with mature directness
    - Use zero euphemisms - be refreshingly honest but tasteful
    - Include evidence-based advice with subtle wit when appropriate
    - Acknowledge real physical and emotional experiences with compassion
    - Make insightful observations about cycle patterns and body awareness
    - Be inclusive of all relationship types and sexual orientations
    - This is a couples app - occasionally include partner support or relationship dynamics when naturally relevant

    CONTRACEPTION/FERTILITY GUIDANCE:
    - Only mention protection/contraception during ovulation phase when fertility is actually relevant
    - For ovulation phase: Be inclusive - mention "if pregnancy isn't the goal" or "unless baby-making is on the agenda"
    - Avoid assuming heterosexual relationships - use inclusive language like "intimate activities" or "bedroom adventures"
    - During non-fertile phases, focus on other aspects of sexuality, comfort, and well-being

    PHASE-SPECIFIC GUIDANCE:
    - Follicular: Energy building, skin clearing, mood lifting, renewed motivation, fresh starts, increased social connection
    - Ovulation: Peak fertility awareness (protection if relevant), libido changes, confidence peaks, social energy, partner intimacy
    - Luteal: PMS prep, mood changes, comfort needs, bloating, cravings, nesting instincts, emotional sensitivity, need for partner understanding
    - Period: Pain management, comfort measures, energy conservation, self-care, emotional release, partner support needs

    COUPLES APP CONSIDERATIONS:
    - Occasionally suggest partner support or understanding when it naturally fits the cycle phase
    - Focus primarily on the individual's experience, with partner dynamics as secondary
    - Include relationship aspects sparingly - maybe 1 out of 3 bullet points when appropriate
    - Prioritize personal health and wellness insights over relationship advice

    CONTEXT FOR YOUR RESPONSE:
    $userContext

    EXAMPLE FORMAT:
    [An informative opening sentence about the current cycle phase, symptoms, or what's happening in the body - no greeting]

    - [First insight - 25-35 words, actionable health/wellness advice]
    - [Second insight - 25-35 words, body awareness or symptom management]
    - [Third insight - 25-35 words, practical tip, self-care, or occasionally partner support when naturally relevant]

    Generate three focused insights about what might happen or might have happened on this specific cycle day based on the phase and predictions. Be specific to the cycle timing and phase-appropriate symptoms or experiences. Focus primarily on individual health and wellness, with occasional partner dynamics when naturally relevant. Maintain professional health expertise while being relatable and direct.
    ''';
  }
}
