import 'dart:async';

import 'package:bebi_app/utils/is_test.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

void logEvent({required String name, Map<String, Object>? parameters}) {
  if (isTest || kDebugMode) return;

  unawaited(
    GetIt.I<FirebaseAnalytics>().logEvent(name: name, parameters: parameters),
  );
}

void logLogin({required String loginMethod, Map<String, Object>? parameters}) {
  if (isTest || kDebugMode) return;

  unawaited(
    GetIt.I<FirebaseAnalytics>().logLogin(
      loginMethod: loginMethod,
      parameters: parameters,
    ),
  );
}

void setUserProperty({required String name, required String value}) {
  if (isTest || kDebugMode) return;

  unawaited(
    GetIt.I<FirebaseAnalytics>().setUserProperty(name: name, value: value),
  );
}

void logShare({
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
