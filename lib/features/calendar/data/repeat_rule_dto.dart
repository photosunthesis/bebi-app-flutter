import 'package:bebi_app/features/calendar/domain/entities/repeat_rule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension RepeatRuleDto on RepeatRule {
  static RepeatRule fromMap(Map<String, dynamic> map) {
    return RepeatRule(
      frequency: RepeatFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
      ),
      occurrences: map['occurrences'],
      excludedDates: map['excluded_dates'] != null
          ? List<DateTime>.from(
              map['excluded_dates'].map((e) => (e as Timestamp).toDate()),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.name,
      if (occurrences != null) 'occurrences': occurrences,
      if (excludedDates != null)
        'excluded_dates': excludedDates!.map(Timestamp.fromDate).toList(),
    };
  }
}
