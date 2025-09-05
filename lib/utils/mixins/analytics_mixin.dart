import 'dart:async';

import 'package:bebi_app/utils/platform/platform_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

mixin AnalyticsMixin {
  void logScreenViewed({
    required String screenName,
    String? screenClassOverride,
  }) {
    if (kDebugMode || kIsTest) return;

    unawaited(
      GetIt.I<FirebaseAnalytics>().logScreenView(screenName: screenName),
    );
  }

  void logUserAction({
    required String action,
    Map<String, Object>? parameters,
  }) {
    if (kDebugMode || kIsTest) return;

    unawaited(
      GetIt.I<FirebaseAnalytics>().logEvent(
        name: 'user_action_$action',
        parameters: parameters,
      ),
    );
  }

  void logAppAction({required String action, Map<String, Object>? parameters}) {
    if (kDebugMode || kIsTest) return;

    unawaited(
      GetIt.I<FirebaseAnalytics>().logEvent(
        name: 'app_action_$action',
        parameters: parameters,
      ),
    );
  }

  void logDataLoaded({
    required String dataType,
    Map<String, Object>? parameters,
  }) {
    if (kDebugMode || kIsTest) return;

    unawaited(
      GetIt.I<FirebaseAnalytics>().logEvent(
        name: 'data_loaded_$dataType',
        parameters: parameters,
      ),
    );
  }

  void logLogin({
    required String loginMethod,
    Map<String, Object>? parameters,
  }) {
    if (kDebugMode || kIsTest) return;

    unawaited(
      GetIt.I<FirebaseAnalytics>().logLogin(
        loginMethod: loginMethod,
        parameters: parameters,
      ),
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
      GetIt.I<FirebaseAnalytics>().logShare(
        method: method,
        contentType: contentType,
        itemId: itemId,
        parameters: parameters,
      ),
    );
  }
}
