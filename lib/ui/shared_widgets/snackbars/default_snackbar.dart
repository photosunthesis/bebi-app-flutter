import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:flutter/material.dart';

enum SnackbarType { primary, secondary, success, error }

extension DefaultSnackbar on BuildContext {
  static String? _currentMessage;

  /// Shows a transient snackbar with the given [message].
  /// Prevents duplicate messages from being shown simultaneously.
  ///
  /// Note: this method already schedules its work inside a post-frame callback
  /// (it uses `WidgetsBinding.instance.addPostFrameCallback` internally), so
  /// callers do NOT need to check `mounted` or wrap their calls in
  /// `WidgetsBinding.instance.addPostFrameCallback(...)`.
  ///
  /// Optional parameters:
  /// - [type]: visual style of the snackbar (default: primary).
  /// - [duration]: how long the snackbar remains visible.
  /// - [suffix]: an optional widget to display alongside the message.
  void showSnackbar(
    String message, {
    SnackbarType type = SnackbarType.primary,
    Duration? duration,
    Widget? suffix,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
              shape: const RoundedRectangleBorder(),
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
    });
  }
}
