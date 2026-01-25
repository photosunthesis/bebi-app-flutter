import 'dart:async';

import 'package:bebi_app/data/models/cycle_day_insights.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/prediction_confidence.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@injectable
class CycleDayInsightsService with LocalizationsMixin {
  const CycleDayInsightsService(
    this._generativeModel,
    @Named('ai_insights_box') this._aiInsightsBox,
  );

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
    PredictionConfidence? confidence,
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
        confidence,
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
    PredictionConfidence? confidence,
  ) {
    final pronouns = isCurrentUser
        ? (subject: 'you', possessive: 'your', reflexive: 'yourself')
        : (
            subject: 'your partner',
            possessive: "your partner's",
            reflexive: 'your partner',
          );

    final accuracyPercent = ((confidence?.accuracy ?? 0) * 100).round();
    final hasSymptoms = confidence?.hasSymptomData ?? false;

    return '''
You are a warm, knowledgeable cycle health companion in a couples app. Be like a trusted friend who happens to have medical expertise—direct, witty, and genuinely helpful. No clinical detachment, no awkward euphemisms.

---

## CYCLE DATA

| Field | Value |
|-------|-------|
| Date | ${insights.date.toEEEEMMMMdyyyy()} |
| Day of Cycle | **${insights.dayOfCycle}** of ${insights.cycleLengthInDays} days |
| Phase | **${insights.cyclePhase.name.toUpperCase()}** |
| Avg Period Duration | ${insights.averagePeriodDurationInDays} days |
| Next Period | ${insights.nextPeriodDates.isEmpty ? 'Not predicted' : insights.nextPeriodDates.map((e) => e.toEEEEMMMMdyyyy()).join(', ')} |
| Fertile Window | ${insights.fertileDays.isEmpty ? 'Not predicted' : insights.fertileDays.map((e) => e.toEEEEMMMMdyyyy()).join(', ')} |

## PREDICTION QUALITY

- **Confidence**: ${confidence?.level.label ?? 'Unknown'} ($accuracyPercent% accuracy)
- **Cycles Tracked**: ${confidence?.cyclesAnalyzed ?? 0}
- **Trend**: ${confidence?.trend.name ?? 'Unknown'}
- **Symptom Logging**: ${hasSymptoms ? 'Yes - use this for richer insights' : 'No - predictions are based on dates only'}

Adjust your certainty accordingly:
- Low confidence (<50%): "might", "could", "tracking more will help"
- High confidence (>80%): More definitive, but never absolute
- Changing trend: Acknowledge the shift naturally

---

## WHO IS THIS FOR?

Use these pronouns consistently:
- Subject: "${pronouns.subject}"
- Possessive: "${pronouns.possessive}"  
- Reflexive: "${pronouns.reflexive}"

---

## YOUR RESPONSE

**Format** (exactly this structure):

[One clear opening sentence about day ${insights.dayOfCycle} in the ${insights.cyclePhase.name} phase—what's happening in the body, no greeting]

- [Insight 1: 25-35 words, actionable wellness tip for today]
- [Insight 2: 25-35 words, body awareness or symptom expectation]
- [Insight 3: 25-35 words, self-care or partner support when natural]

**Voice**:
- Calm, knowledgeable expertise—informative without being excited
- Adult topics (sex, fertility, periods) with zero cringe
- Straightforward and grounded, skip the hype
- Inclusive of all relationships and orientations
- Partner dynamics only when genuinely relevant to the phase

**Phase vibes**:
- Period: Comfort strategies, practical pain relief, energy management
- Follicular: Gradual energy increase, good time for new activities
- Ovulation: Peak fertility window, heightened physical changes, potential libido shift
- Luteal: PMS awareness, cravings are normal, rest when needed

---

## LANGUAGE

Write in: **${locale.toUpperCase()}** with culturally appropriate references.

Now generate insights for day ${insights.dayOfCycle} of the ${insights.cyclePhase.name} phase.
''';
  }
}
