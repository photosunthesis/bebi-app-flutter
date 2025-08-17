enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String toTitle() => name[0].toUpperCase() + name.substring(1);
}
