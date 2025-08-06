part of 'cycles_cubit.dart';

@freezed
abstract class CyclesState with _$CyclesState {
  const CyclesState._();

  const factory CyclesState({
    required DateTime focusedDate,
    required List<CycleLog> cycleLogs,
    required bool shouldSetupCycles,
    required bool loading,
    required bool loadingCycleDayInsights,
    CycleDayInsights? focusedCycleDayInsights,
    String? error,
  }) = _CyclesState;

  factory CyclesState.initial() => CyclesState(
    focusedDate: DateTime.now(),
    cycleLogs: [],
    loading: false,
    loadingCycleDayInsights: false,
    shouldSetupCycles: false,
  );

  CycleLog? get focusedDatePeriodLog => cycleLogs.firstWhereOrNull(
    (e) => e.date.isSameDay(focusedDate) && e.type == LogType.period,
  );

  CycleLog? get focusedDateSymptomLog => cycleLogs.firstWhereOrNull(
    (e) => e.date.isSameDay(focusedDate) && e.type == LogType.symptom,
  );

  CycleLog? get focusedDateIntimacyLog => cycleLogs.firstWhereOrNull(
    (e) => e.date.isSameDay(focusedDate) && e.type == LogType.intimacy,
  );

  CycleLog? get focusedDateOvulationLog => cycleLogs.firstWhereOrNull(
    (e) => e.date.isSameDay(focusedDate) && e.type == LogType.ovulation,
  );

  List<CycleLog> get focusedDateLogs =>
      cycleLogs.where((e) => e.date.isSameDay(focusedDate)).toList();
}
