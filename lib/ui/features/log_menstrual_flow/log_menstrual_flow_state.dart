part of 'log_menstrual_flow_cubit.dart';

sealed class LogMenstrualFlowState {
  const LogMenstrualFlowState();
}

class LogMenstrualFlowLoadingState extends LogMenstrualFlowState {
  const LogMenstrualFlowLoadingState();
}

class LogMenstrualFlowLoadedState extends LogMenstrualFlowState {
  const LogMenstrualFlowLoadedState();
}

class LogMenstrualFlowSuccessState extends LogMenstrualFlowState {
  const LogMenstrualFlowSuccessState();
}

class LogMenstrualFlowErrorState extends LogMenstrualFlowState {
  const LogMenstrualFlowErrorState(this.error);
  final String error;
}
