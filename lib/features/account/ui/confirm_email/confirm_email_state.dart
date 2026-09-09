part of 'confirm_email_cubit.dart';

sealed class ConfirmEmailState {
  const ConfirmEmailState();
}

class ConfirmEmailLoadingState extends ConfirmEmailState {
  const ConfirmEmailLoadingState();
}

class ConfirmEmailLoadedState extends ConfirmEmailState {
  const ConfirmEmailLoadedState(this.email);
  final String email;
}

class ConfirmEmailErrorState extends ConfirmEmailState {
  const ConfirmEmailErrorState(this.error);
  final String error;
}

class ConfirmEmailSuccessState extends ConfirmEmailState {
  const ConfirmEmailSuccessState();
}
