import 'dart:async';

import 'package:bebi_app/config/firebase_services.dart';
import 'package:flutter/foundation.dart';

FutureOr<T?> guard<T>(
  FutureOr<T> Function() body, {
  void Function(Object error, StackTrace stackTrace)? onError,
  void Function()? onComplete,
  bool disableLogging = false,
}) async {
  try {
    return await body();
  } catch (e, s) {
    if (kDebugMode || disableLogging) {
      debugPrint('Error caught by guard: $e\n$s');
    } else {
      FirebaseServices.crashlytics.recordError(e, s, fatal: true);
    }
    onError?.call(e, s);
    return null;
  } finally {
    onComplete?.call();
  }
}
