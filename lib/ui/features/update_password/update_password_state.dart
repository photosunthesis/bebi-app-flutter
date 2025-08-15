part of 'update_password_cubit.dart';

@freezed
sealed class UpdatePasswordState with _$UpdatePasswordState {
  const factory UpdatePasswordState.data() = UpdatePasswordStateData;
  const factory UpdatePasswordState.loading() = UpdatePasswordStateLoading;
  const factory UpdatePasswordState.success() = UpdatePasswordStateSuccess;
  const factory UpdatePasswordState.error(String error) = UpdatePasswordStateError;
}