part of 'profile_setup_cubit.dart';

sealed class ProfileSetupState {
  const ProfileSetupState();
}

class ProfileSetupLoadingState extends ProfileSetupState {
  const ProfileSetupLoadingState();
}

class ProfileSetupLoadedState extends ProfileSetupState {
  const ProfileSetupLoadedState([this.profilePicture]);
  final File? profilePicture;
}

class ProfileSetupSuccessState extends ProfileSetupState {
  const ProfileSetupSuccessState();
}

class ProfileSetupErrorState extends ProfileSetupState {
  const ProfileSetupErrorState(this.error);
  final String error;
}
