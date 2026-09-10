import 'package:equatable/equatable.dart';

enum RepeatFrequency { daily, weekly, monthly, yearly, doNotRepeat }

class RepeatRule extends Equatable {
  const RepeatRule({
    required this.frequency,
    this.occurrences,
    this.excludedDates,
  });

  final RepeatFrequency frequency;
  final int? occurrences;
  final List<DateTime>? excludedDates;

  RepeatRule copyWith({
    RepeatFrequency? frequency,
    int? occurrences,
    List<DateTime>? excludedDates,
  }) {
    return RepeatRule(
      frequency: frequency ?? this.frequency,
      occurrences: occurrences ?? this.occurrences,
      excludedDates: excludedDates ?? this.excludedDates,
    );
  }

  @override
  List<Object?> get props => [frequency, occurrences, excludedDates];
}
