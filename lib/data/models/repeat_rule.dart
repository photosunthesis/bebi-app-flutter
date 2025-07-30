import 'package:bebi_app/constants/hive_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'repeat_rule.freezed.dart';
part 'repeat_rule.g.dart';

@HiveType(typeId: HiveTypeIds.repeatFrequency)
enum RepeatFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
  @HiveField(4)
  custom,
  @HiveField(5)
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

  @HiveType(typeId: HiveTypeIds.repeatRule)
  const factory RepeatRule({
    @HiveField(0) required RepeatFrequency frequency,
    @HiveField(1) @Default(1) int interval,
    @HiveField(2) List<int>? daysOfWeek,
    @HiveField(3) DateTime? endDate,
    @HiveField(4) int? occurrences,
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
