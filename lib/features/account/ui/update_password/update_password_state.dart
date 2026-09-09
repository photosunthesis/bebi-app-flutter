part of 'update_password_cubit.dart';

sealed class UpdatePasswordState {
  const UpdatePasswordState();
}

class UpdatePasswordLoadedState extends UpdatePasswordState {
  const UpdatePasswordLoadedState();
}

class UpdatePasswordLoadingState extends UpdatePasswordState {
  const UpdatePasswordLoadingState();
}

class UpdatePasswordSuccessState extends UpdatePasswordState {
  const UpdatePasswordSuccessState();
}

class UpdatePasswordErrorState extends UpdatePasswordState {
  const UpdatePasswordErrorState(this.error);
  final String error;
}
