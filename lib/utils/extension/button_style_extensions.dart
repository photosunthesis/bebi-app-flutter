import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/material.dart';

extension ButtonStyleExtensions on ButtonStyle {
  ButtonStyle asPrimary(BuildContext context) {
    return copyWith(
      shadowColor: WidgetStatePropertyAll(context.colorScheme.shadow),
      foregroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? context.colorScheme.onTertiary
            : context.colorScheme.onPrimary,
      ),
      backgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? context.colorScheme.secondary
            : context.colorScheme.primary,
      ),
    );
  }
}
