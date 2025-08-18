part of 'cycle_calendar_cubit.dart';

sealed class CycleCalendarState {
  const CycleCalendarState();
}

class CycleCalendarLoadingState extends CycleCalendarState {
  const CycleCalendarLoadingState();
}

class CycleCalendarLoadedState extends CycleCalendarState {
  const CycleCalendarLoadedState(this.cycleLogs);
  final List<CycleLog> cycleLogs;
}

class CycleCalendarErrorState extends CycleCalendarState {
  const CycleCalendarErrorState(this.error);
  final String error;
}
