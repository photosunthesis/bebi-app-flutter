import 'package:bebi_app/constants/hive_type_ids.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

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

@HiveType(typeId: HiveTypeIds.repeatRule)
class RepeatRule extends Equatable {
  const RepeatRule({
    required this.frequency,
    this.daysOfWeek,
    this.endDate,
    this.occurrences,
    this.excludedDates,
  });

  factory RepeatRule.fromMap(Map<String, dynamic> map) {
    return RepeatRule(
      frequency: RepeatFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
      ),
      daysOfWeek: map['days_of_week'] != null
          ? List<int>.from(map['days_of_week'])
          : null,
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

  @HiveField(0)
  final RepeatFrequency frequency;
  @HiveField(1)
  final List<int>? daysOfWeek;
  @HiveField(2)
  final DateTime? endDate;
  @HiveField(3)
  final int? occurrences;
  @HiveField(4)
  final List<DateTime>? excludedDates;

  RepeatRule copyWith({
    RepeatFrequency? frequency,
    List<int>? daysOfWeek,
    DateTime? endDate,
    int? occurrences,
    List<DateTime>? excludedDates,
  }) {
    return RepeatRule(
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      endDate: endDate ?? this.endDate,
      occurrences: occurrences ?? this.occurrences,
      excludedDates: excludedDates ?? this.excludedDates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.name,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (endDate != null) 'end_date': Timestamp.fromDate(endDate!),
      if (occurrences != null) 'occurrences': occurrences,
      if (excludedDates != null)
        'excluded_dates': excludedDates!.map(Timestamp.fromDate).toList(),
    };
  }

  @override
  List<Object?> get props => [
    frequency,
    daysOfWeek,
    endDate,
    occurrences,
    excludedDates,
  ];
}
