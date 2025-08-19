import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RepeatFrequency {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
  doNotRepeat;

  String get label => switch (this) {
    RepeatFrequency.daily => 'Daily',
    RepeatFrequency.weekly => 'Weekly',
    RepeatFrequency.monthly => 'Monthly',
    RepeatFrequency.yearly => 'Yearly',
    RepeatFrequency.custom => 'Custom',
    RepeatFrequency.doNotRepeat => 'Do not repeat',
  };
}

class RepeatRule extends Equatable {
  const RepeatRule({
    required this.frequency,
    this.endDate,
    this.occurrences,
    this.excludedDates,
  });

  factory RepeatRule.fromMap(Map<String, dynamic> map) {
    return RepeatRule(
      frequency: RepeatFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
      ),
      endDate: map['end_date'] != null
          ? (map['end_date'] as Timestamp).toDate()
          : null,
      occurrences: map['occurrences'],
      excludedDates: map['excluded_dates'] != null
          ? List<DateTime>.from(
              map['excluded_dates'].map((e) => (e as Timestamp).toDate()),
            )
          : null,
    );
  }

  final RepeatFrequency frequency;
  final DateTime? endDate;
  final int? occurrences;
  final List<DateTime>? excludedDates;

  RepeatRule copyWith({
    RepeatFrequency? frequency,
    DateTime? endDate,
    int? occurrences,
    List<DateTime>? excludedDates,
  }) {
    return RepeatRule(
      frequency: frequency ?? this.frequency,
      endDate: endDate ?? this.endDate,
      occurrences: occurrences ?? this.occurrences,
      excludedDates: excludedDates ?? this.excludedDates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.name,
      if (endDate != null) 'end_date': Timestamp.fromDate(endDate!),
      if (occurrences != null) 'occurrences': occurrences,
      if (excludedDates != null)
        'excluded_dates': excludedDates!.map(Timestamp.fromDate).toList(),
    };
  }

  @override
  List<Object?> get props => [frequency, endDate, occurrences, excludedDates];
}
