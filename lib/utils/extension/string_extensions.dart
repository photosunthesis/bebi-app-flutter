import 'package:intl/intl.dart';

extension StringExtensions on String {
  DateTime? toDateTime(String format) => DateFormat(format).parse(this);

  DateTime? toDateTimeStrict(String format) =>
      DateFormat(format).tryParseStrict(this);

  DateTime? toEEEEMMMMdyyyyDate() => toDateTimeStrict('EEEE MMMM d, yyyy');

  DateTime? toHHmmaTime() => toDateTimeStrict('h:mm a');
}
