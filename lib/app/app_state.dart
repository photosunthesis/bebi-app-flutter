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

  final AsyncValue<UserProfileView?> userProfileAsync;
  final AsyncValue<UserProfileView?> partnerProfileAsync;
  final bool userIsSignedIn;

  AppState copyWith({
    AsyncValue<UserProfileView?>? userProfileAsync,
    AsyncValue<UserProfileView?>? partnerProfileAsync,
    bool? userIsSignedIn,
  }) {
    return AppState(
      userProfileAsync: userProfileAsync ?? this.userProfileAsync,
      partnerProfileAsync: partnerProfileAsync ?? this.partnerProfileAsync,
      userIsSignedIn: userIsSignedIn ?? this.userIsSignedIn,
    );
  }
}
