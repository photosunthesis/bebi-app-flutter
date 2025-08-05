import 'dart:async';
import 'dart:io';

import 'package:bebi_app/config/firebase_services.dart';
import 'package:flutter/foundation.dart';

bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

FutureOr<T?> guard<T>(
  FutureOr<T> Function() body, {
  void Function(Object error, StackTrace stackTrace)? onError,
  void Function()? onComplete,
  bool disableLogging = false,
}) async {
  try {
    return await body();
  } catch (e, s) {
    if ((kDebugMode && _isTest) || disableLogging) {
      debugPrint('Error caught by guard: $e\n$s');
    } else {
      unawaited(FirebaseServices.crashlytics.recordError(e, s));
    }
    onError?.call(e, s);
    return null;
  } finally {
    onComplete?.call();
  }
}
