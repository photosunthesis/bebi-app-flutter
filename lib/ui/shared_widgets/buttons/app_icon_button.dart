import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/material.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({super.key, required this.icon, this.onTap});

  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: context.colorScheme.onSecondary,
          width: UiConstants.borderWidth,
        ),
        borderRadius: BorderRadius.circular(UiConstants.borderRadiusValue),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(UiConstants.borderRadiusValue),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(icon, color: context.colorScheme.primary, size: 22),
        ),
      ),
    );
  }
}
