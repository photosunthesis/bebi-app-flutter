part of 'sign_in_cubit.dart';

sealed class SignInState {
  const SignInState();
}

class SignInInitial extends SignInState {
  const SignInInitial();
}

class SignInLoading extends SignInState {
  const SignInLoading();
}

class SignInSuccess extends SignInState {
  const SignInSuccess();
}

class SignInFailure extends SignInState {
  const SignInFailure(this.error);

  final String error;
}
