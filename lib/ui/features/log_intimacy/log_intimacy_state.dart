part of 'log_intimacy_cubit.dart';

@freezed
sealed class LogIntimacyState with _$LogIntimacyState {
  const factory LogIntimacyState.data() = LogIntimacyStateData;
  const factory LogIntimacyState.loading() = LogIntimacyStateLoading;
  const factory LogIntimacyState.error(String error) = LogIntimacyStateError;
  const factory LogIntimacyState.success() = LogIntimacyStateSuccess;
}
