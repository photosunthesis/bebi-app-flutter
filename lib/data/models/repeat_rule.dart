import 'package:cloud_firestore/cloud_firestore.dart';

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

class RepeatRule {
  const RepeatRule({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek,
    this.endDate,
    this.count,
  });

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
      count: map['count'],
    );
  }

  final RepeatFrequency frequency;
  final int interval; // e.g., every n units
  final List<int>? daysOfWeek; // 1=Monday, 7=Sunday, for weekly repeats
  final DateTime? endDate;
  final int? count;

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.name,
      'interval': interval,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (endDate != null) 'end_date': Timestamp.fromDate(endDate!),
      if (count != null) 'count': count,
    };
  }
}
