part of 'cycle_setup_cubit.dart';

@freezed
sealed class CycleSetupState with _$CycleSetupState {
  const factory CycleSetupState.initial() = CycleSetupStateInitial;
  const factory CycleSetupState.loading() = CycleSetupStateLoading;
  const factory CycleSetupState.success() = CycleSetupStateSuccess;
  const factory CycleSetupState.error(String error) = CycleSetupStateError;
}
