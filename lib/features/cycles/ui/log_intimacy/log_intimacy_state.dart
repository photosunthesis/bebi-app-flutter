part of 'log_intimacy_cubit.dart';

sealed class LogIntimacyState {
  const LogIntimacyState();
}

class LogIntimmacyLoadedState extends LogIntimacyState {
  const LogIntimmacyLoadedState();
}

class LogIntimacyLoadingState extends LogIntimacyState {
  const LogIntimacyLoadingState();
}

class LogIntimacyErrorState extends LogIntimacyState {
  const LogIntimacyErrorState(this.error);
  final String error;
}

class LogIntimacySuccessState extends LogIntimacyState {
  const LogIntimacySuccessState();
}
