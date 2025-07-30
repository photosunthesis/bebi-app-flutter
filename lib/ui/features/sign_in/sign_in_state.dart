part of 'sign_in_cubit.dart';

@freezed
sealed class SignInState with _$SignInState {
  const factory SignInState.initial() = SignInInitial;
  const factory SignInState.loading() = SignInLoading;
  const factory SignInState.success() = SignInSuccess;
  const factory SignInState.failure(String error) = SignInFailure;
}
