import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';

/// Extension to show a custom snackbar with optional suffix widget.
/// If [suffix] is provided, it replaces the default dismiss button.
extension DefaultSnackbar on BuildContext {
  /// Shows a snackbar with the given [message].
  ///
  /// [duration] sets how long the snackbar is visible (default: 4 seconds).
  /// [suffix] is an optional widget shown at the end of the snackbar row.
  /// If [suffix] is provided, it replaces the default dismiss button.
  void showSnackbar(String message, {Duration? duration, Widget? suffix}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();

    final snackBarContent = Text(
      message,
      style: textTheme.titleSmall?.copyWith(color: colorScheme.onPrimary),
    );

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: snackBarContent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: colorScheme.onSurface,
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        duration: duration ?? 4.seconds,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
