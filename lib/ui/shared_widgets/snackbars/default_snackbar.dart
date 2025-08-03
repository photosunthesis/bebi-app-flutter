import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';

enum SnackbarType { success, error, base }

extension DefaultSnackbar on BuildContext {
  void showSnackbar(
    String message, {
    SnackbarType type = SnackbarType.error,
    Duration? duration,
    Widget? suffix,
  }) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();

    final snackBarContent = Text(
      message,
      style: textTheme.titleSmall?.copyWith(color: colorScheme.onPrimary),
    );

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: snackBarContent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: type == SnackbarType.success
            ? colorScheme.inversePrimary
            : type == SnackbarType.base
            ? colorScheme.primary
            : colorScheme.error,
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        duration: duration ?? 4.seconds,
        shape: const RoundedRectangleBorder(
          borderRadius: UiConstants.borderRadius,
        ),
      ),
    );
  }
}
