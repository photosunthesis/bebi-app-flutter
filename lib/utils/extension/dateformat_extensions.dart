import 'package:intl/intl.dart';

extension DateFormatExtensions on DateFormat {
  DateTime parseStrict(String inputString) {
    final date = parse(inputString);
    final reformattedString = format(date);
    
    if (reformattedString != inputString) {
      throw FormatException('Invalid date format', inputString);
    }
    
    return date;
  }
  
  DateTime? tryParse(String inputString) {
    try {
      return parse(inputString);
    } catch (_) {
      return null;
    }
  }
  
  DateTime? tryParseStrict(String inputString) {
    try {
      return parseStrict(inputString);
    } catch (_) {
      return null;
    }
  }
}