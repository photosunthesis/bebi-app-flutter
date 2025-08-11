import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

FutureOr<T?> guard<T>(
  FutureOr<T> Function() body, {
  void Function(Object error, StackTrace stackTrace)? onError,
  void Function()? onComplete,
  bool Function(Object? error)? logWhen,
  bool disableLogging = false,
}) async {
  try {
    return await body();
  } catch (e, s) {
    if ((kDebugMode && _isTest) || disableLogging) {
      debugPrint('Error caught by guard: $e\n$s');
    } else {
      if (logWhen?.call(e) ?? true) {
        unawaited(GetIt.I<FirebaseCrashlytics>().recordError(e, s));
      }
    }
    onError?.call(e, s);
    return null;
  } finally {
    onComplete?.call();
  }
}
