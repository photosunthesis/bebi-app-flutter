import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum OptionStyle { primary, secondary, destructive }

class Option<T> {
  const Option({
    required this.text,
    required this.value,
    this.style = OptionStyle.secondary,
  });

  final String text;
  final T value;
  final OptionStyle style;
}

class OptionsBottomDialog<T> extends StatelessWidget {
  const OptionsBottomDialog._({
    super.key,
    required this.title,
    this.description,
    required this.options,
  });

  final String title;
  final String? description;
  final List<Option<T>> options;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<Option<T>> options,
    String? description,
    bool useRootNavigator = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: false,
      isDismissible: isDismissible,
      barrierColor: context.colorScheme.primary.withAlpha(80),
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => OptionsBottomDialog._(
        title: title,
        description: description,
        options: options,
      ),
      useRootNavigator: useRootNavigator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UiConstants.padding,
            ),
            child: Text(title, style: context.primaryTextTheme.titleLarge),
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UiConstants.padding,
              ),
              child: Text(
                description!,
                style: context.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...options.map((option) => _buildOption(context, option)),
          const SafeArea(child: SizedBox(height: 12)),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, Option<T> option) {
    ButtonStyle buttonStyle;

    switch (option.style) {
      case OptionStyle.primary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: context.colorScheme.primary,
          foregroundColor: context.colorScheme.onPrimary,
        );
        break;
      case OptionStyle.secondary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: context.colorScheme.surface,
          foregroundColor: context.colorScheme.primary,
        );
        break;
      case OptionStyle.destructive:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: context.colorScheme.error,
          foregroundColor: context.colorScheme.surface,
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UiConstants.padding,
        vertical: 2,
      ),
      child: ElevatedButton(
        style: buttonStyle.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 44)),
        ),
        onPressed: () => context.pop(option.value),
        child: Text(option.text.toUpperCase()),
      ),
    );
  }
}
