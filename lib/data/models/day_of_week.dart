enum DayOfWeek {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday;

  factory DayOfWeek.fromIndex(int index) {
    return switch (index) {
      0 => sunday,
      1 => monday,
      2 => tuesday,
      3 => wednesday,
      4 => thursday,
      5 => friday,
      6 => saturday,
      _ => throw ArgumentError('Invalid index: $index'),
    };
  }

  String toTitle() => switch (this) {
    sunday => 'Sunday',
    monday => 'Monday',
    tuesday => 'Tuesday',
    wednesday => 'Wednesday',
    thursday => 'Thursday',
    friday => 'Friday',
    saturday => 'Saturday',
  };
}
