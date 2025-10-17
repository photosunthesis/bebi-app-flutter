import 'dart:async';

import 'package:bebi_app/config/firebase_providers.dart';
import 'package:bebi_app/config/utility_packages_provider.dart';
import 'package:bebi_app/utils/platform/platform_utils.dart';
import 'package:flutter/foundation.dart';

mixin AnalyticsMixin {
  void logScreenViewed({
    required String screenName,
    String? screenClassOverride,
  }) {
    if (kDebugMode || kIsTest) return;

    unawaited(
      globalContainer
          .read(firebaseAnalyticsProvider)
          .logScreenView(screenName: screenName),
    );
  }

  void logUserAction({
    required String action,
    Map<String, Object>? parameters,
  }) {
    if (kDebugMode || kIsTest) return;

    unawaited(
      globalContainer
          .read(firebaseAnalyticsProvider)
          .logEvent(name: 'user_action_$action', parameters: parameters),
    );
  }

  void logAppAction({required String action, Map<String, Object>? parameters}) {
    if (kDebugMode || kIsTest) return;

    unawaited(
      globalContainer
          .read(firebaseAnalyticsProvider)
          .logEvent(name: 'app_action_$action', parameters: parameters),
    );
  }

  void logDataLoaded({
    required String dataType,
    Map<String, Object>? parameters,
  }) {
    if (kDebugMode || kIsTest) return;

    unawaited(
      globalContainer
          .read(firebaseAnalyticsProvider)
          .logEvent(name: 'data_loaded_$dataType', parameters: parameters),
    );
  }

  void logLogin({
    required String loginMethod,
    Map<String, Object>? parameters,
  }) {
    if (kDebugMode || kIsTest) return;

    unawaited(
      globalContainer
          .read(firebaseAnalyticsProvider)
          .logLogin(loginMethod: loginMethod, parameters: parameters),
    );
  }

  void logShare({
    required String method,
    required String contentType,
    required String itemId,
    Map<String, Object>? parameters,
  }) {
    if (kDebugMode || kIsTest) return;

    unawaited(
      globalContainer
          .read(firebaseAnalyticsProvider)
          .logShare(
            method: method,
            contentType: contentType,
            itemId: itemId,
            parameters: parameters,
          ),
    );
  }
}
