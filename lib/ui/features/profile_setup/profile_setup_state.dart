part of 'profile_setup_cubit.dart';

@freezed
abstract class ProfileSetupState with _$ProfileSetupState {
  const factory ProfileSetupState({
    @Default(false) bool loading,
    @Default(false) bool success,
    File? profilePicture,
    String? error,
  }) = _ProfileSetupState;
}
