part of 'cycles_cubit.dart';

class CyclesState extends Equatable {
  const CyclesState({
    required this.focusedDate,
    this.cycleLogs = const [],
    this.isViewingCurrentUser = true,
    this.aiSummary,
    this.focusedDateInsights,
    this.userProfile,
    this.partnerProfile,
    this.isLoading = false,
    this.isInsightLoading = false,
    this.error,
  });

  final DateTime focusedDate;
  final List<CycleLog> cycleLogs;
  final bool isViewingCurrentUser;
  final String? aiSummary;
  final CycleDayInsights? focusedDateInsights;
  final UserProfile? userProfile;
  final UserProfile? partnerProfile;
  final bool isLoading;
  final bool isInsightLoading;
  final String? error;

  List<CycleLog> get focusedDateLogs =>
      cycleLogs.where((e) => e.date.isSameDay(focusedDate)).toList();

  CyclesState copyWith({
    DateTime? focusedDate,
    List<CycleLog>? cycleLogs,
    bool? isViewingCurrentUser,
    String? aiSummary,
    CycleDayInsights? focusedDateInsights,
    UserProfile? userProfile,
    UserProfile? partnerProfile,
    bool? isLoading,
    bool? isInsightLoading,
    String? error,
  }) {
    return CyclesState(
      focusedDate: focusedDate ?? this.focusedDate,
      cycleLogs: cycleLogs ?? this.cycleLogs,
      isViewingCurrentUser: isViewingCurrentUser ?? this.isViewingCurrentUser,
      aiSummary: aiSummary ?? this.aiSummary,
      focusedDateInsights: focusedDateInsights ?? this.focusedDateInsights,
      userProfile: userProfile ?? this.userProfile,
      partnerProfile: partnerProfile ?? this.partnerProfile,
      isLoading: isLoading ?? this.isLoading,
      isInsightLoading: isInsightLoading ?? this.isInsightLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    focusedDate,
    cycleLogs,
    isViewingCurrentUser,
    aiSummary,
    focusedDateInsights,
    userProfile,
    partnerProfile,
    isLoading,
    isInsightLoading,
    error,
  ];
}
