import 'dart:async';

import 'package:bebi_app/utils/is_test.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

abstract class AnalyticsUtils {
  static void logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    if (isTest || kDebugMode) return;

    unawaited(
      GetIt.I<FirebaseAnalytics>().logEvent(name: name, parameters: parameters),
    );
  }

  static void logLogin({
    required String loginMethod,
    Map<String, Object>? parameters,
  }) {
    if (isTest || kDebugMode) return;

    unawaited(
      GetIt.I<FirebaseAnalytics>().logLogin(
        loginMethod: loginMethod,
        parameters: parameters,
      ),
    );
  }

  static void setUserProperty({required String name, required String value}) {
    if (isTest || kDebugMode) return;

    unawaited(
      GetIt.I<FirebaseAnalytics>().setUserProperty(name: name, value: value),
    );
  }

  static void logShare({
    required String method,
    required String contentType,
    required String itemId,
    Map<String, Object>? parameters,
  }) {
    if (isTest || kDebugMode) return;

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
