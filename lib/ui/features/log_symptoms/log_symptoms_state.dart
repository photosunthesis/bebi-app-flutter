part of 'log_symptoms_cubit.dart';

@freezed
sealed class LogSymptomsState with _$LogSymptomsState {
  const factory LogSymptomsState.loading() = LogSymptomsStateLoading;
  const factory LogSymptomsState.data() = LogSymptomsStateData;
  const factory LogSymptomsState.success() = LogSymptomsStateSuccess;
  const factory LogSymptomsState.error(String error) = LogSymptomsStateError;
}
