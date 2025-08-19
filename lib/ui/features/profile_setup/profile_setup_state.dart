part of 'profile_setup_cubit.dart';

sealed class ProfileSetupState {
  const ProfileSetupState();
}

class ProfileSetupLoadingState extends ProfileSetupState {
  const ProfileSetupLoadingState();
}

class ProfileSetupLoadedState extends ProfileSetupState {
  const ProfileSetupLoadedState({this.photo, this.displayName, this.birthDate});
  final String? photo;
  final String? displayName;
  final DateTime? birthDate;
  bool get isPhotoUrl => photo?.startsWith('http') ?? false;
}

class ProfileSetupSuccessState extends ProfileSetupState {
  const ProfileSetupSuccessState();
}

class ProfileSetupErrorState extends ProfileSetupState {
  const ProfileSetupErrorState(this.error);
  final String error;
}
