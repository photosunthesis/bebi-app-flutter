import 'dart:async';

import 'package:bebi_app/utils/platform/platform_utils_io.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

sealed class AsyncValue<T> extends Equatable {
  const AsyncValue();

  R map<R>({
    R Function()? loading,
    R Function(T value)? data,
    R Function(Object? error)? error,
    required R Function() orElse,
  }) {
    return switch (this) {
      AsyncLoading<T>() => loading?.call() ?? orElse(),
      AsyncData<T>(:final value) => data?.call(value) ?? orElse(),
      AsyncError<T>() => error?.call((this as AsyncError<T>).error) ?? orElse(),
    };
  }

  T? asData() {
    return map(data: (value) => value, orElse: () => null);
  }

  bool get isLoading => this is AsyncLoading<T>;

  static FutureOr<AsyncValue<T>> guard<T>(
    FutureOr<T> Function() future, {
    bool disableLogging = false,
  }) async {
    try {
      return AsyncData(await future());
    } catch (err, stack) {
      if ((kDebugMode && kIsTest) || disableLogging) {
        debugPrint('Error caught by guard: $err\n$stack');
      } else {
        unawaited(Sentry.captureException(err, stackTrace: stack));
      }

      return AsyncError(err, stack);
    }
  }
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();

  @override
  List<Object?> get props => [];
}

class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.value);
  final T value;

  @override
  List<Object?> get props => [value];
}

class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(this.error, [this.stackTrace]);
  final Object? error;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [error, stackTrace];
}
