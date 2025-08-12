enum DayOfWeek {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday;

  String toTitle() => name[0].toUpperCase() + name.substring(1);
}
