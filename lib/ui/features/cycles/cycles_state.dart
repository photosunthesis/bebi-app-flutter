part of 'cycles_cubit.dart';

sealed class CyclesState {
  const CyclesState();
}

class CyclesLoadingState extends CyclesState {
  const CyclesLoadingState();
}

class CyclesLoadedState extends CyclesState {
  CyclesLoadedState({
    DateTime? focusedDate,
    this.cycleLogs = const [],
    this.showCurrentUserCycleData = true,
    this.aiSummary,
    this.focusedDateInsights,
    this.userProfile,
    this.partnerProfile,
  }) : focusedDate = focusedDate ?? DateTime.now();

  final DateTime focusedDate;
  final List<CycleLog> cycleLogs;
  final bool showCurrentUserCycleData;
  final String? aiSummary;
  final CycleDayInsights? focusedDateInsights;
  final UserProfile? userProfile;
  final UserProfile? partnerProfile;

  List<CycleLog> get focusedDateLogs =>
      cycleLogs.where((e) => e.date.isSameDay(focusedDate)).toList();
}

class CyclesErrorState extends CyclesState {
  const CyclesErrorState(this.error);
  final String error;
}
