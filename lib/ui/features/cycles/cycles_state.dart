part of 'cycles_cubit.dart';

class CyclesState extends Equatable {
  const CyclesState({
    required this.focusedDate,
    this.isViewingCurrentUser = true,
    this.aiSummary = const AsyncData(''),
    this.cycleLogs = const AsyncData([]),
    this.insights = const AsyncData(null),
  });

  final DateTime focusedDate;
  final bool isViewingCurrentUser;
  final AsyncValue<String> aiSummary;
  final AsyncValue<List<CycleLog>> cycleLogs;
  final AsyncValue<CycleDayInsights?> insights;

  String? get errorMessage {
    return switch ([cycleLogs, insights, aiSummary]) {
      [AsyncError(:final error), ...] => error.toString(),
      [_, AsyncError(:final error), ...] => error.toString(),
      [_, _, AsyncError(:final error), ...] => error.toString(),
      _ => null,
    };
  }

  CyclesState copyWith({
    DateTime? focusedDate,
    bool? isViewingCurrentUser,
    AsyncValue<String>? aiSummary,
    AsyncValue<List<CycleLog>>? cycleLogs,
    AsyncValue<CycleDayInsights?>? insights,
  }) {
    return CyclesState(
      focusedDate: focusedDate ?? this.focusedDate,
      isViewingCurrentUser: isViewingCurrentUser ?? this.isViewingCurrentUser,
      aiSummary: aiSummary ?? this.aiSummary,
      cycleLogs: cycleLogs ?? this.cycleLogs,
      insights: insights ?? this.insights,
    );
  }

  @override
  List<Object?> get props => [
    focusedDate,
    isViewingCurrentUser,
    aiSummary,
    cycleLogs,
    insights,
  ];
}
