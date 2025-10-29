import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    // Format with thousand separators
    final number = int.tryParse(digitsOnly);
    if (number == null) {
      return oldValue;
    }

    final formatted = _formatter.format(number);

    // Calculate new cursor position
    int selectionIndex = formatted.length;
    if (newValue.selection.baseOffset < newValue.text.length) {
      // User is editing in the middle, try to maintain cursor position
      final cursorPosition = newValue.selection.baseOffset;
      
      // Count digits before cursor in old value
      int digitsBefore = 0;
      for (int i = 0; i < cursorPosition && i < newValue.text.length; i++) {
        if (RegExp(r'\d').hasMatch(newValue.text[i])) {
          digitsBefore++;
        }
      }
      
      // Find position in formatted string
      int digitsCount = 0;
      for (int i = 0; i < formatted.length; i++) {
        if (RegExp(r'\d').hasMatch(formatted[i])) {
          digitsCount++;
          if (digitsCount == digitsBefore) {
            selectionIndex = i + 1;
            break;
          }
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
