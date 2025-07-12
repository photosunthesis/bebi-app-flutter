extension IntExtensions on int {
  Duration get days => Duration(days: this);

  Duration get hours => Duration(hours: this);

  Duration get minutes => Duration(minutes: this);

  Duration get seconds => Duration(seconds: this);

  Duration get milliseconds => Duration(milliseconds: this);
}
