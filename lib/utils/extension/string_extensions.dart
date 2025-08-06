import 'package:intl/intl.dart';

extension StringExtensions on String {
  DateTime? toDateTime(String format) =>
      DateFormat(format).tryParseStrict(this);

  DateTime? toEEEEMMMMdyyyyDate() => toDateTime('EEEE MMMM d, yyyy');

  DateTime? toHHmmaTime() => toDateTime('h:mm a');
}
