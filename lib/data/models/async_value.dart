import 'package:equatable/equatable.dart';

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
  const AsyncError(this.error);
  final Object? error;

  @override
  List<Object?> get props => [error];
}
