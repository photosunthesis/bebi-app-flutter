import 'dart:async';

import 'package:bebi_app/utils/platform/platform_utils_io.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

sealed class AsyncValue<T> with EquatableMixin {
  const AsyncValue();

  R maybeMap<R>({
    R Function()? loading,
    R Function(T value)? data,
    R Function(Object? error, StackTrace? stackTrace)? error,
    required R Function() orElse,
  }) {
    return switch (this) {
      AsyncLoading<T>() => loading?.call() ?? orElse(),
      AsyncData<T>(:final value) => data?.call(value) ?? orElse(),
      AsyncError<T>() =>
        error?.call(
              (this as AsyncError<T>).error,
              (this as AsyncError<T>).stackTrace,
            ) ??
            orElse(),
    };
  }

  R map<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object? error, StackTrace? stackTrace) error,
  }) {
    return switch (this) {
      AsyncLoading<T>() => loading.call(),
      AsyncData<T>(:final value) => data.call(value),
      AsyncError<T>() => error.call(
        (this as AsyncError<T>).error,
        (this as AsyncError<T>).stackTrace,
      ),
    };
  }

  T? asData() {
    return maybeMap(data: (value) => value, orElse: () => null);
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
        unawaited(GetIt.I<FirebaseCrashlytics>().recordError(err, stack));
      }

      return AsyncError(err, stack);
    }
  }

  @override
  List<Object?> get props => switch (this) {
    AsyncLoading<T>() => [],
    AsyncData<T>(:final value) => [value],
    AsyncError<T>(:final error, :final stackTrace) => [error, stackTrace],
  };
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.value);
  final T value;
}

class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(this.error, [this.stackTrace]);
  final Object? error;
  final StackTrace? stackTrace;
}
