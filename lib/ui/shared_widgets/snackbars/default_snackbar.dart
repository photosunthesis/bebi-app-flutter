import 'package:bebi_app/constants/ui_constants.dart';
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

    final snackBarContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(message)),
        const SizedBox(width: 8),
        suffix ??
            IconButton(
              icon: Icon(Icons.close, color: colorScheme.onPrimary, size: 16),
              visualDensity: VisualDensity.compact,
              onPressed: ScaffoldMessenger.of(this).hideCurrentSnackBar,
              padding: EdgeInsets.zero,
              tooltip: 'Dismiss',
            ),
      ],
    );

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: snackBarContent,
        padding: const EdgeInsets.fromLTRB(16, 6, 2, 6),
        backgroundColor: colorScheme.onSurface,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? 4.seconds,
        shape: RoundedRectangleBorder(
          borderRadius: UiConstants.defaultBorderRadius,
        ),
      ),
    );
  }
}
