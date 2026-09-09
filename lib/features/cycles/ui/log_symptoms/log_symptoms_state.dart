part of 'log_symptoms_cubit.dart';

sealed class LogSymptomsState {
  const LogSymptomsState();
}

class LogSymptomsLoadingState extends LogSymptomsState {
  const LogSymptomsLoadingState();
}

class LogSymptomsLoadedState extends LogSymptomsState {
  const LogSymptomsLoadedState();
}

class LogSymptomsSuccessState extends LogSymptomsState {
  const LogSymptomsSuccessState();
}

class LogSymptomsErrorState extends LogSymptomsState {
  const LogSymptomsErrorState(this.error);
  final String error;
}
