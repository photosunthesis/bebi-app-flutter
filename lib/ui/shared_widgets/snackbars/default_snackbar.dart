import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';

enum SnackbarType { primary, secondary, success, error }

extension DefaultSnackbar on BuildContext {
  static String? _currentMessage;

  void showSnackbar(
    String message, {
    SnackbarType type = SnackbarType.primary,
    Duration? duration,
    Widget? suffix,
  }) {
    if (_currentMessage == message) return;

    _currentMessage = message;
    ScaffoldMessenger.of(this).hideCurrentSnackBar();

    final snackBarContent = Text(
      message,
      style: textTheme.titleSmall?.copyWith(
        color: type == SnackbarType.secondary
            ? colorScheme.secondary
            : colorScheme.onPrimary,
      ),
    );

    ScaffoldMessenger.of(this)
        .showSnackBar(
          SnackBar(
            content: snackBarContent,
            duration: duration ?? 4.seconds,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            backgroundColor: switch (type) {
              SnackbarType.success => colorScheme.inversePrimary,
              SnackbarType.secondary => colorScheme.surface,
              SnackbarType.primary => colorScheme.primary,
              SnackbarType.error => colorScheme.error,
            },
          ),
        )
        .closed
        .then((_) {
          if (_currentMessage == message) _currentMessage = null;
        });
  }
}
