import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/material.dart';

class ShadowContainer extends StatelessWidget {
  const ShadowContainer({
    required this.child,
    this.color,
    this.shape = BoxShape.rectangle,
    this.shadowOffset = const Offset(0, 0),
    this.shadowBlurRadius = 4,
    super.key,
  });

  final Widget child;
  final Color? color;
  final BoxShape shape;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: shape,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color ?? context.colorScheme.shadow.withAlpha(10),
            blurRadius: shadowBlurRadius,
            offset: shadowOffset,
            spreadRadius: -4,
          ),
        ],
      ),
      child: child,
    );
  }
}
