part of 'app_cubit.dart';

/// Global app state.
///
/// Stuff here is accessible from anywhere in the app. Add global stuff as needed.
class AppState {
  const AppState({
    this.coupleContextAsync = const AsyncData(null),
    this.userIsSignedIn = false,
  });

  final AsyncValue<CoupleContext?> coupleContextAsync;
  final bool userIsSignedIn;

  AppState copyWith({
    AsyncValue<CoupleContext?>? coupleContextAsync,
    bool? userIsSignedIn,
  }) {
    return AppState(
      coupleContextAsync: coupleContextAsync ?? this.coupleContextAsync,
      userIsSignedIn: userIsSignedIn ?? this.userIsSignedIn,
    );
  }
}
