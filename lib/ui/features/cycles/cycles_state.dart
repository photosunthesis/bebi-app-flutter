part of 'cycles_cubit.dart';

@freezed
abstract class CyclesState with _$CyclesState {
  const factory CyclesState({
    required DateTime focusedDate,
    required List<CycleLog> cycleLogs,
    required bool loading,
    required bool showCurrentUserCycleData,
    required bool loadingAiSummary,
    String? aiSummary,
    CycleDayInsights? focusedCycleDayInsights,
    UserProfile? userProfile,
    UserProfile? partnerProfile,
    String? error,
  }) = _CyclesState;

  factory CyclesState.initial() => CyclesState(
    focusedDate: DateTime.now(),
    cycleLogs: [],
    loading: false,
    loadingAiSummary: false,
    showCurrentUserCycleData: true,
  );
}
