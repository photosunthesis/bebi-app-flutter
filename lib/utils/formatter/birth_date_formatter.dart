import 'package:flutter/services.dart';

class BirthDateFormatter extends TextInputFormatter {
  const BirthDateFormatter();

  static const _mask = 'DD/MM/YYYY';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final buffer = StringBuffer();
    int digitIndex = 0;

    for (int i = 0; i < _mask.length; i++) {
      if (_mask[i] == 'D' || _mask[i] == 'M' || _mask[i] == 'Y') {
        if (digitIndex < digits.length) {
          buffer.write(digits[digitIndex]);
          digitIndex++;
        } else {
          buffer.write(_mask[i]);
        }
      } else {
        buffer.write(_mask[i]);
      }
    }

    final result = buffer.toString();

    // If user erased and it's back to the mask, clear the field
    if (digits.isEmpty || result == _mask) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Calculate new cursor position
    int selectionIndex = result.indexOf(RegExp(r'[DMY]'));
    if (selectionIndex == -1) {
      selectionIndex = result.length;
    } else {
      selectionIndex =
          digits.length +
          (digits.length > 2 ? 1 : 0) +
          (digits.length > 4 ? 1 : 0);
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: selectionIndex.clamp(0, result.length),
      ),
    );
  }
}
