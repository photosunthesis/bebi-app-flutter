import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';

enum SnackbarType { success, error, secondary }

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
      style: textTheme.titleSmall?.copyWith(
        color: type == SnackbarType.secondary
            ? colorScheme.secondary
            : colorScheme.onPrimary,
      ),
    );

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: snackBarContent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: type == SnackbarType.success
            ? colorScheme.inversePrimary
            : type == SnackbarType.secondary
            ? colorScheme.surface
            : colorScheme.error,
        elevation: 3,
        duration: duration ?? 4.seconds,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
