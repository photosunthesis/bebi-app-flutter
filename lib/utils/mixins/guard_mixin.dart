import 'dart:async';

import 'package:bebi_app/utils/platform/platform_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

mixin GuardMixin {
  FutureOr<T?> guard<T>(
    FutureOr<T> Function() body, {
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onComplete,
    bool disableLogging = false,
  }) async {
    try {
      return await body();
    } catch (e, s) {
      if ((kDebugMode && isTest) || disableLogging) {
        debugPrint('Error caught by guard: $e\n$s');
      } else {
        unawaited(Sentry.captureException(e, stackTrace: s));
      }
      onError?.call(e, s);
      return null;
    } finally {
      onComplete?.call();
    }
  }
}
