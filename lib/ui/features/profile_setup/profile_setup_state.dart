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
    bool profilePictureChanged = false,
    String? error,
    bool errorChanged = false,
  }) {
    return ProfileSetupState(
      loading: loading ?? this.loading,
      success: success ?? this.success,
      profilePicture: profilePictureChanged
          ? profilePicture
          : this.profilePicture,
      error: errorChanged ? error : this.error,
    );
  }
}
