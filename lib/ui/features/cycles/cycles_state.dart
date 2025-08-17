part of 'cycles_cubit.dart';

class CyclesState extends Equatable {
  const CyclesState({
    required this.focusedDate,
    required this.cycleLogs,
    required this.loading,
    required this.showCurrentUserCycleData,
    required this.loadingAiSummary,
    this.aiSummary,
    this.focusedCycleDayInsights,
    this.userProfile,
    this.partnerProfile,
    this.error,
  });

  factory CyclesState.initial() => CyclesState(
    focusedDate: DateTime.now(),
    cycleLogs: [],
    loading: false,
    loadingAiSummary: false,
    showCurrentUserCycleData: true,
  );

  final DateTime focusedDate;
  final List<CycleLog> cycleLogs;
  final bool loading;
  final bool showCurrentUserCycleData;
  final bool loadingAiSummary;
  final String? aiSummary;
  final CycleDayInsights? focusedCycleDayInsights;
  final UserProfile? userProfile;
  final UserProfile? partnerProfile;
  final String? error;

  List<CycleLog> get focusedDateLogs =>
      cycleLogs.where((e) => e.date.isSameDay(focusedDate)).toList();

  CyclesState copyWith({
    DateTime? focusedDate,
    List<CycleLog>? cycleLogs,
    bool? loading,
    bool? showCurrentUserCycleData,
    bool? loadingAiSummary,
    String? aiSummary,
    CycleDayInsights? focusedCycleDayInsights,
    UserProfile? userProfile,
    UserProfile? partnerProfile,
    String? error,
  }) {
    return CyclesState(
      focusedDate: focusedDate ?? this.focusedDate,
      cycleLogs: cycleLogs ?? this.cycleLogs,
      loading: loading ?? this.loading,
      showCurrentUserCycleData:
          showCurrentUserCycleData ?? this.showCurrentUserCycleData,
      loadingAiSummary: loadingAiSummary ?? this.loadingAiSummary,
      aiSummary: aiSummary ?? this.aiSummary,
      focusedCycleDayInsights:
          focusedCycleDayInsights ?? this.focusedCycleDayInsights,
      userProfile: userProfile ?? this.userProfile,
      partnerProfile: partnerProfile ?? this.partnerProfile,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    focusedDate,
    cycleLogs,
    loading,
    showCurrentUserCycleData,
    loadingAiSummary,
    aiSummary,
    focusedCycleDayInsights,
    userProfile,
    partnerProfile,
    error,
  ];
}
