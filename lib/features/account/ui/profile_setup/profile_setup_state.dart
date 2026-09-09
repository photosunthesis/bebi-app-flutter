part of 'profile_setup_cubit.dart';

class ProfileSetupState {
  const ProfileSetupState({
    this.photo,
    this.displayName,
    this.birthDate,
    this.userIsLoggedIn = false,
    this.updateProfileAsync = const AsyncData<bool>(false),
  });

  final String? photo;
  final String? displayName;
  final DateTime? birthDate;
  final bool userIsLoggedIn;
  final AsyncValue<bool> updateProfileAsync;

  ProfileSetupState copyWith({
    String? photo,
    bool photoChanged = false,
    String? displayName,
    DateTime? birthDate,
    bool? userIsLoggedIn,
    AsyncValue<bool>? updateProfileAsync,
  }) {
    return ProfileSetupState(
      photo: photoChanged ? photo : this.photo,
      displayName: displayName ?? this.displayName,
      birthDate: birthDate ?? this.birthDate,
      userIsLoggedIn: userIsLoggedIn ?? this.userIsLoggedIn,
      updateProfileAsync: updateProfileAsync ?? this.updateProfileAsync,
    );
  }
}
