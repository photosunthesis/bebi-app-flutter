part of 'cycles_cubit.dart';

@freezed
abstract class CyclesState with _$CyclesState {
  const factory CyclesState({
    required List<CycleLog> cycleLogs,
    required bool shouldSetupCycles,
    required bool loading,
    String? error,
  }) = _CyclesState;

  factory CyclesState.initial() => const CyclesState(
    cycleLogs: [],
    loading: false,
    shouldSetupCycles: false,
  );
}
