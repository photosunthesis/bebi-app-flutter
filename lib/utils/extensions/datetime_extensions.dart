import 'package:intl/intl.dart';

extension DatetimeExtensions on DateTime {
  String toMMMdyyyy() => DateFormat('MMM d yyyy').format(this);

  String toMMMd() => DateFormat('MMM d').format(this);

  String toMMMMyyyy() => DateFormat('MMMM yyyy').format(this);

  String toEEEEMMMMd() => DateFormat('EEEE, MMMM d').format(this);

  String toEEEEMMMd() => DateFormat('EEEE, MMM d').format(this);

  String toEEEMMMd() => DateFormat('EEE, MMM d').format(this);

  String toMMMMd() => DateFormat('MMMM d').format(this);

  String toEEEEMMMMdyyyy() => DateFormat('EEEE MMMM d, yyyy').format(this);

  String toEEEEMMMdyyyy() => DateFormat('EEE MMM d, yyyy').format(this);

  String toEEEEMMMMdyyyyhhmma() =>
      DateFormat('EEEE MMMM d, yyyy h:mm a').format(this);

  String toEEEMMMdyyyyhhmma() =>
      DateFormat('EEE, MMM d, yyyy h:mm a').format(this);

  String toMMddyyyy() => DateFormat('MM/dd/yyyy').format(this);

  String toHHmma() => DateFormat('h:mm a').format(this);

  String toDateRange(DateTime other) {
    if (isSameDay(other)) {
      return '${toEEEEMMMdyyyy()} ${toHHmma()} → ${other.toHHmma()}';
    }

    if (isSameMonth(other)) {
      return '${toMMMd()} - ${other.toMMMdyyyy()}';
    }

    return '${toEEEEMMMdyyyy()} - ${other.toEEEEMMMdyyyy()}';
  }

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  String get weekDayInitial => DateFormat('E').format(this).split('').first;

  String toEEE() => DateFormat('EEE').format(this);

  String toTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = (now.year - year) * 12 + (now.month - month);
      if (months > 0 && months < 12) {
        return '${months}mo ago';
      }

      final years = months ~/ 12;

      if (years > 0) return '${years}y ago';

      return toMMMdyyyy();
    }
  }

  String get dayOfWeek => DateFormat('EEEE').format(this);

  bool get isToday => isSameDay(DateTime.now());

  DateTime earlierDate(DateTime other) => isBefore(other) ? this : other;

  DateTime laterDate(DateTime other) => isAfter(other) ? this : other;

  DateTime noTime() => DateTime(year, month, day);

  DateTime withRoundedOffTime() =>
      DateTime(year, month, day, hour, (minute ~/ 10) * 10);
}
