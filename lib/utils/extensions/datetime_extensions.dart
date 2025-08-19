import 'package:intl/intl.dart';

extension DatetimeExtensions on DateTime {
  String toMMMMyyyy() => DateFormat('MMMM yyyy').format(this);

  String toEEEEMMMMd() => DateFormat('EEEE, MMMM d').format(this);

  String toEEEEMMMd() => DateFormat('EEEE, MMM d').format(this);

  String toMMMMd() => DateFormat('MMMM d').format(this);

  String toEEEEMMMMdyyyy() => DateFormat('EEEE MMMM d, yyyy').format(this);

  String toEEEEMMMdyyyy() => DateFormat('EEE MMM d, yyyy').format(this);

  String toEEEEMMMMdyyyyhhmma() =>
      DateFormat('EEEE MMMM d, yyyy h:mm a').format(this);

  String toMMddyyyy() => DateFormat('MM/dd/yyyy').format(this);

  String toHHmma() => DateFormat('h:mm a').format(this);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  String get weekDayInitial => DateFormat('E').format(this).split('').first;

  String toEEE() => DateFormat('EEE').format(this);

  String get dayOfWeek => DateFormat('EEEE').format(this);

  bool get isToday => isSameDay(DateTime.now());

  DateTime earlierDate(DateTime other) => isBefore(other) ? this : other;

  DateTime laterDate(DateTime other) => isAfter(other) ? this : other;

  DateTime noTime() => DateTime(year, month, day);
}
