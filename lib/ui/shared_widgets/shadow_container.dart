import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/material.dart';

class ShadowContainer extends StatelessWidget {
  const ShadowContainer({
    required this.child,
    this.color,
    this.shape = BoxShape.rectangle,
    this.offset = const Offset(0, 0),
    super.key,
  });

  final Widget child;
  final Color? color;
  final BoxShape shape;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(UiConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: color ?? context.colorScheme.shadow.withAlpha(10),
            blurRadius: 4,
            offset: offset,
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}
