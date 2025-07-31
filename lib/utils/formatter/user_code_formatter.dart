import 'package:flutter/services.dart';

class UserCodeFormatter extends TextInputFormatter {
  const UserCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawInput = newValue.text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();

    final buffer = StringBuffer();

    for (var i = 0; i < rawInput.length && i < 6; i++) {
      if (i == 3) buffer.write('-');
      buffer.write(rawInput[i]);
    }

    final formatted = buffer.toString();

    // Calculate the new cursor position
    final selectionIndex = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
