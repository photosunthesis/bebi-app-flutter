import 'package:flutter/services.dart';

class BirthDateFormatter extends TextInputFormatter {
  static const maxLength = 10; // MM/DD/YYYY

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final isErasing = oldValue.text.length > newValue.text.length;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      buffer.write(digits[i]);
      if ((i == 1 || i == 3) && i < digits.length - 1) {
        buffer.write('/');
      }
    }
    String result = buffer.toString();

    if (isErasing && result.isNotEmpty && result[result.length - 1] == '/') {
      result = result.substring(0, result.length - 1);
    }

    if (result.length > maxLength) {
      result = result.substring(0, maxLength);
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
