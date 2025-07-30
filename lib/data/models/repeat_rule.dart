import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'repeat_rule.freezed.dart';

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

@freezed
abstract class RepeatRule with _$RepeatRule {
  const RepeatRule._();
  const factory RepeatRule({
    required RepeatFrequency frequency,
    @Default(1) int interval,
    List<int>? daysOfWeek,
    DateTime? endDate,
    int? occurrences,
  }) = _RepeatRule;

  factory RepeatRule.fromMap(Map<String, dynamic> map) {
    return RepeatRule(
      frequency: RepeatFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
      ),
      interval: map['interval'] ?? 1,
      daysOfWeek: map['days_of_week'] != null
          ? List<int>.from(map['days_of_week'])
          : null,
      endDate: map['end_date'] != null
          ? (map['end_date'] as Timestamp).toDate()
          : null,
      occurrences: map['occurrences'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.name,
      'interval': interval,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (endDate != null) 'end_date': Timestamp.fromDate(endDate!),
      if (occurrences != null) 'occurrences': occurrences,
    };
  }
}
