import 'dart:async';

import 'package:bebi_app/config/firebase_providers.dart';
import 'package:bebi_app/config/utility_packages_provider.dart';
import 'package:bebi_app/utils/platform/platform_utils.dart';
import 'package:flutter/foundation.dart';

mixin GuardMixin {
  FutureOr<void> guard<T>(
    FutureOr<T> Function() body, {
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onComplete,
    bool Function(Object error, StackTrace stackTrace)? logWhen,
    bool disableLogging = false,
  }) async {
    try {
      await body();
    } catch (e, s) {
      if ((kDebugMode && kIsTest) ||
          disableLogging ||
          (logWhen != null && !logWhen(e, s))) {
        debugPrint('Error caught by guard: $e\n$s');
      } else {
        unawaited(
          globalContainer.read(firebaseCrashlyticsProvider).recordError(e, s),
        );
      }
      onError?.call(e, s);
      return;
    } finally {
      onComplete?.call();
    }
  }
}
