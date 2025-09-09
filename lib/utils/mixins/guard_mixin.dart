import 'dart:async';

import 'package:bebi_app/utils/platform/platform_utils.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

mixin GuardMixin {
  FutureOr<T?> guard<T>(
    FutureOr<T> Function() body, {
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onComplete,
    bool Function(Object error, StackTrace stackTrace)? logWhen,
    bool disableLogging = false,
  }) async {
    try {
      return await body();
    } catch (e, s) {
      if ((kDebugMode && kIsTest) ||
          disableLogging ||
          (logWhen != null && !logWhen(e, s))) {
        debugPrint('Error caught by guard: $e\n$s');
      } else {
        unawaited(GetIt.I<FirebaseCrashlytics>().recordError(e, s));
      }
      onError?.call(e, s);
      return null;
    } finally {
      onComplete?.call();
    }
  }
}
