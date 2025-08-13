part of 'log_menstrual_flow_cubit.dart';

@freezed
sealed class LogMenstrualFlowState with _$LogMenstrualFlowState {
  const factory LogMenstrualFlowState.loading() = LogMenstrualFlowLoading;
  const factory LogMenstrualFlowState.data() = LogMenstrualFlowData;
  const factory LogMenstrualFlowState.success() = LogMenstrualFlowSuccess;
  const factory LogMenstrualFlowState.error(String error) =
      LogMenstrualFlowError;
}
