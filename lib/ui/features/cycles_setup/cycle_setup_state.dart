part of 'cycle_setup_cubit.dart';

sealed class CycleSetupState {
  const CycleSetupState();
}

class CycleSetupInitialState extends CycleSetupState {
  const CycleSetupInitialState();
}

class CycleSetupLoadingState extends CycleSetupState {
  const CycleSetupLoadingState();
}

class CycleSetupSuccessState extends CycleSetupState {
  const CycleSetupSuccessState();
}

class CycleSetupErrorState extends CycleSetupState {
  const CycleSetupErrorState(this.error);
  final String error;
}
