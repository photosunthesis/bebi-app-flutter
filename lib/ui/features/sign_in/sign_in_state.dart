part of 'sign_in_cubit.dart';

sealed class SignInState {
  const SignInState();
}

final class SignInLoadingState extends SignInState {
  const SignInLoadingState();
}

final class SignInLoadedState extends SignInState {
  const SignInLoadedState();
}

final class SignInSuccessState extends SignInState {
  const SignInSuccessState();
}

final class SignInErrorState extends SignInState {
  const SignInErrorState(this.error);
  final String error;
}
