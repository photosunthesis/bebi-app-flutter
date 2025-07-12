part of 'profile_setup_cubit.dart';

class ProfileSetupState {
  const ProfileSetupState({
    this.loading = false,
    this.success = false,
    this.profilePicture,
    this.error,
  });

  final bool loading;
  final bool success;
  final File? profilePicture;
  final String? error;

  ProfileSetupState copyWith({
    bool? loading,
    bool? success,
    File? profilePicture,
    String? error,
  }) {
    return ProfileSetupState(
      loading: loading ?? this.loading,
      success: success ?? this.success,
      profilePicture: profilePicture ?? this.profilePicture,
      error: error ?? this.error,
    );
  }
}
