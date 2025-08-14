part of 'confirm_email_cubit.dart';

@freezed
sealed class ConfirmEmailState with _$ConfirmEmailState {
  const factory ConfirmEmailState.data(String email) = ConfirmEmailStateData;
  const factory ConfirmEmailState.loading() = ConfirmEmailStateLoading;
  const factory ConfirmEmailState.success() = ConfirmEmailStateSuccess;
  const factory ConfirmEmailState.error(String error) = ConfirmEmailStateError;
}
