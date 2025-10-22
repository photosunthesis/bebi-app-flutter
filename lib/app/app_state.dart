part of 'app_cubit.dart';

/// Global app state.
///
/// Stuff here is accessible from anywhere in the app. Add global stuff as needed.
class AppState {
  const AppState({
    this.userProfileAsync = const AsyncData(null),
    this.partnerProfileAsync = const AsyncData(null),
    this.userIsSignedIn = false,
  });

  final AsyncValue<UserProfileWithPictureDto?> userProfileAsync;
  final AsyncValue<UserProfileWithPictureDto?> partnerProfileAsync;
  final bool userIsSignedIn;

  AppState copyWith({
    AsyncValue<UserProfileWithPictureDto?>? userProfileAsync,
    AsyncValue<UserProfileWithPictureDto?>? partnerProfileAsync,
    bool? userIsSignedIn,
  }) {
    return AppState(
      userProfileAsync: userProfileAsync ?? this.userProfileAsync,
      partnerProfileAsync: partnerProfileAsync ?? this.partnerProfileAsync,
      userIsSignedIn: userIsSignedIn ?? this.userIsSignedIn,
    );
  }
}
