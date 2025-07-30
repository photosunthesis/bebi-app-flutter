import 'package:intl/intl.dart';

extension DatetimeExtensions on DateTime {
  String toMMMMyyyy() => DateFormat('MMMM yyyy').format(this);

  String toEEEEMMMMd() => DateFormat('EEEE MMMM d').format(this);

  String toEEEEMMMMdyyyy() => DateFormat('EEEE MMMM d, yyyy').format(this);

  String toEEEEMMMMdyyyyhhmma() =>
      DateFormat('EEEE MMMM d, yyyy h:mm a').format(this);

  String toHHmma() => DateFormat('h:mm a').format(this);

  String toEEEMMMd() => DateFormat('EEE MMM d').format(this);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  String get weekDayInitial => DateFormat('EEE').format(this);

  String get dayOfWeek => DateFormat('EEEE').format(this);

  bool get isToday => isSameDay(DateTime.now());
}
