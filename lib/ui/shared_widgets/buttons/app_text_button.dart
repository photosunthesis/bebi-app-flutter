import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/material.dart';

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.text,
    this.onTap,
    this.padding,
    this.decoration,
    this.textStyle,
  });

  final VoidCallback? onTap;
  final String text;
  final EdgeInsets? padding;
  final BoxDecoration? decoration;
  final TextStyle? textStyle;

  static Widget primary({
    required String text,
    VoidCallback? onTap,
    EdgeInsets? padding = const EdgeInsets.all(8),
  }) {
    return Builder(
      builder: (context) {
        return AppTextButton(
          text: text,
          onTap: onTap,
          padding: padding,
          decoration: BoxDecoration(
            color: context.colorScheme.primary,
            borderRadius: BorderRadius.circular(UiConstants.borderRadiusValue),
          ),
          textStyle: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration:
          decoration ??
          BoxDecoration(
            border: Border.all(
              color: context.colorScheme.onSecondary,
              width: UiConstants.borderWidth,
            ),
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(UiConstants.borderRadiusValue),
          ),
      child: InkWell(
        borderRadius: BorderRadius.circular(UiConstants.borderRadiusValue),
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(6),
          child: Text(
            text,
            style:
                textStyle ??
                context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
