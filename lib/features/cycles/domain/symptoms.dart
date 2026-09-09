enum Symptoms {
  cramps,
  appetiteChanges,
  moodiness,
  headache,
  nausea,
  bloating,
  acne;

  factory Symptoms.fromString(String value) {
    return Symptoms.values.firstWhere(
      (e) => e.label == value,
      orElse: () => throw ArgumentError('Invalid label: $value'),
    );
  }

  String get label {
    final words = name
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();

    return words[0].toUpperCase() + words.substring(1);
  }
}
