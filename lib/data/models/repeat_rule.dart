import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RepeatFrequency with LocalizationsMixin {
  daily,
  weekly,
  monthly,
  yearly,
  doNotRepeat;

  String get label => switch (this) {
    RepeatFrequency.daily => l10n.repeatDaily,
    RepeatFrequency.weekly => l10n.repeatWeekly,
    RepeatFrequency.monthly => l10n.repeatMonthly,
    RepeatFrequency.yearly => l10n.repeatYearly,
    RepeatFrequency.doNotRepeat => l10n.repeatDoNotRepeat,
  };
}

class RepeatRule extends Equatable {
  const RepeatRule({
    required this.frequency,
    this.occurrences,
    this.excludedDates,
  });

  factory RepeatRule.fromMap(Map<String, dynamic> map) {
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

  Map<String, dynamic> toMap() {
    return {
      'frequency': frequency.name,
      if (occurrences != null) 'occurrences': occurrences,
      if (excludedDates != null)
        'excluded_dates': excludedDates!.map(Timestamp.fromDate).toList(),
    };
  }

  @override
  List<Object?> get props => [frequency, occurrences, excludedDates];
}
