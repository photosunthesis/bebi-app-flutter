import 'dart:async';

import 'package:bebi_app/features/cycles/data/cycle_insights_prompt.dart';
import 'package:bebi_app/features/cycles/domain/cycle_day_insights.dart';
import 'package:bebi_app/features/cycles/domain/prediction_confidence.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@injectable
class AiInsightsRepository with LocalizationsMixin {
  const AiInsightsRepository(
    this._generativeModel,
    @Named('ai_insights_box') this._aiInsightsBox,
  );

  final GenerativeModel _generativeModel;
  final Box<String> _aiInsightsBox;

  Future<String> generate(
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

      final prompt = CycleInsightsPrompt.generate(
        insights: cycleDayInsights,
        isCurrentUser: isCurrentUser,
        locale: locale,
        confidence: confidence,
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
}
