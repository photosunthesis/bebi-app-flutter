import 'dart:async';

import 'package:bebi_app/config/firebase_providers.dart';
import 'package:bebi_app/config/hive_providers.dart';
import 'package:bebi_app/data/models/cycle_day_insights.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final cycleDayInsightsServiceProvider = Provider.autoDispose(
  (ref) => CycleDayInsightsService(
    ref.read(generativeModelProvider),
    ref.read(aiInsightsBoxProvider),
  ),
);

class CycleDayInsightsService with LocalizationsMixin {
  const CycleDayInsightsService(this._generativeModel, this._aiInsightsBox);

  final GenerativeModel _generativeModel;
  final Box<String> _aiInsightsBox;

  CycleDayInsights getInsightsFromDateAndEvents(
    DateTime date,
    List<CycleLog> events,
  ) {
    final sortedEvents = events.sortedBy((e) => e.date);
    final periodEvents = sortedEvents.where((e) => e.type == LogType.period);
    final ovulationEvents = sortedEvents.where(
      (e) => e.type == LogType.ovulation,
    );

    if (periodEvents.isEmpty) {
      throw ArgumentError(l10n.noPeriodDataError);
    }

    final periodGroups = _groupPeriodEventsByProximity(periodEvents.toList());

    if (periodGroups.isEmpty) {
      throw ArgumentError(l10n.unableToDetermineCycleError);
    }

    final currentPeriodGroup = _findCurrentPeriodGroup(date, periodGroups);
    final cycleStart = currentPeriodGroup.first.date;
    final nextPeriodGroup = _findNextPeriodGroup(
      periodGroups,
      currentPeriodGroup,
    );

    final nextCycleStart = nextPeriodGroup.first.date;

    final dayOfCycle = date.noTime().difference(cycleStart.noTime()).inDays + 1;
    final cycleLengthInDays = nextCycleStart
        .noTime()
        .difference(cycleStart.noTime())
        .inDays;

    final currentFertileWindow = _getCurrentFertileWindow(
      ovulationEvents.map((e) => e.date).toList(),
      cycleStart,
      nextCycleStart,
    );

    final cyclePhase = _getCyclePhase(date, sortedEvents.toList());
    final averagePeriodDurationInDays = _calculateAveragePeriodDays(
      periodGroups,
    );

    return CycleDayInsights(
      cyclePhase: cyclePhase,
      date: date,
      dayOfCycle: dayOfCycle,
      cycleLengthInDays: cycleLengthInDays,
      averagePeriodDurationInDays: averagePeriodDurationInDays,
      nextPeriodDates: nextPeriodGroup.map((log) => log.date).toList(),
      fertileDays: currentFertileWindow,
    );
  }

  List<List<CycleLog>> _groupPeriodEventsByProximity(List<CycleLog> events) {
    final periodGroups = <List<CycleLog>>[];

    for (final event in events) {
      final currentGroup = periodGroups.lastOrNull;
      // 14 days is the max distance between two period events
      if (currentGroup == null ||
          event.date.difference(currentGroup.last.date).inDays > 14) {
        periodGroups.add([event]);
      } else {
        currentGroup.add(event);
      }
    }

    return periodGroups;
  }

  List<CycleLog> _findCurrentPeriodGroup(
    DateTime date,
    List<List<CycleLog>> periodGroups,
  ) {
    final normalizedDate = date.noTime();

    for (final periodGroup in periodGroups) {
      final periodDates = periodGroup.map((log) => log.date.noTime()).toList();

      if (periodDates.any(
        (periodDate) =>
            periodDate.isAtSameMomentAs(normalizedDate) ||
            (periodDate.isBefore(normalizedDate) &&
                normalizedDate.difference(periodDate).inDays <= 7),
      )) {
        return periodGroup;
      }
    }

    for (var i = 0; i < periodGroups.length - 1; i++) {
      final currentGroup = periodGroups[i];
      final nextGroup = periodGroups[i + 1];
      final currentGroupEndDate = currentGroup
          .map((log) => log.date.noTime())
          .last;
      final nextGroupStartDate = nextGroup
          .map((log) => log.date.noTime())
          .first;

      if (normalizedDate.isAfter(currentGroupEndDate) &&
          normalizedDate.isBefore(nextGroupStartDate)) {
        return currentGroup;
      }
    }

    return periodGroups.first;
  }

  List<CycleLog> _findNextPeriodGroup(
    List<List<CycleLog>> periodGroups,
    List<CycleLog> currentPeriodGroup,
  ) {
    final currentIndex = periodGroups.indexOf(currentPeriodGroup);
    if (currentIndex < periodGroups.length - 1) {
      return periodGroups[currentIndex + 1];
    }
    return periodGroups.first;
  }

  List<DateTime> _getCurrentFertileWindow(
    List<DateTime> ovulationDates,
    DateTime cycleStart,
    DateTime? nextCycleStart,
  ) {
    if (ovulationDates.isEmpty) return [];
    if (nextCycleStart == null) {
      return ovulationDates.where((date) => date.isAfter(cycleStart)).toList();
    }
    return ovulationDates
        .where(
          (date) => date.isBefore(nextCycleStart) && date.isAfter(cycleStart),
        )
        .toList();
  }

  CyclePhase _getCyclePhase(DateTime date, List<CycleLog> allCycleLogs) {
    final normalizedDate = date.noTime();

    final periodLogs = allCycleLogs
        .where((log) => log.type == LogType.period)
        .map((log) => log.date.noTime())
        .toList();
    final ovulationLogs = allCycleLogs
        .where((log) => log.type == LogType.ovulation)
        .map((log) => log.date.noTime())
        .toList();

    if (periodLogs.any((periodDate) => periodDate.isSameDay(normalizedDate))) {
      return CyclePhase.period;
    }

    if (ovulationLogs.any(
      (ovulationDate) => ovulationDate.isSameDay(normalizedDate),
    )) {
      return CyclePhase.ovulation;
    }

    final previousPeriodDate = _findClosestDate(
      periodLogs.where((date) => date.isBefore(normalizedDate)),
      isLatest: true,
    );
    final nextPeriodDate = _findClosestDate(
      periodLogs.where((date) => date.isAfter(normalizedDate)),
      isLatest: false,
    );
    final previousOvulationDate = _findClosestDate(
      ovulationLogs.where((date) => date.isBefore(normalizedDate)),
      isLatest: true,
    );

    if (previousPeriodDate != null) {
      final ovulationAfterPreviousPeriod = _findClosestDate(
        ovulationLogs.where((date) => date.isAfter(previousPeriodDate)),
        isLatest: false,
      );

      if (ovulationAfterPreviousPeriod != null &&
          normalizedDate.isAfter(previousPeriodDate) &&
          normalizedDate.isBefore(ovulationAfterPreviousPeriod)) {
        return CyclePhase.follicular;
      }
    }

    if (previousOvulationDate != null &&
        nextPeriodDate != null &&
        normalizedDate.isAfter(previousOvulationDate) &&
        normalizedDate.isBefore(nextPeriodDate)) {
      return CyclePhase.luteal;
    }

    return CyclePhase.luteal;
  }

  DateTime? _findClosestDate(
    Iterable<DateTime> dates, {
    required bool isLatest,
  }) {
    return dates.fold<DateTime?>(
      null,
      (prev, curr) =>
          prev == null || (isLatest ? curr.isAfter(prev) : curr.isBefore(prev))
          ? curr
          : prev,
    );
  }

  int _calculateAveragePeriodDays(List<List<CycleLog>> periodGroups) {
    if (periodGroups.isEmpty) {
      throw ArgumentError(l10n.noPeriodDataForCycleError);
    }

    final periodLengths = periodGroups.map((group) => group.length).toList();
    return periodLengths.average.round();
  }

  Future<String> generateAiInsights(
    CycleDayInsights cycleDayInsights, {
    required bool isCurrentUser,
    required String locale,
    bool useCache = true,
  }) async {
    try {
      final date = cycleDayInsights.date.toIso8601String().substring(0, 10);
      final key = '${date}_${isCurrentUser ? 'self' : 'partner'}';
      final cachedInsights = _aiInsightsBox.get(key);
      if (cachedInsights != null && useCache) return cachedInsights;

      final prompt = _generateInsightsPrompt(
        cycleDayInsights,
        isCurrentUser,
        locale,
      );

      final response = await _generativeModel.generateContent([
        Content.text(prompt),
      ]);

      if (response.text == null) throw ArgumentError();

      unawaited(_aiInsightsBox.put(key, response.text!));

      return response.text!;
    } catch (_) {
      throw ArgumentError(l10n.aiInsightsGenerationError);
    }
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
    - For ovulation phase: Use supportive, empowering language like "a great time to use your preferred protection methods" or "perfect opportunity to practice safe intimacy"
    - Frame protection as self-care and empowerment, focusing on choice and control over your body
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
