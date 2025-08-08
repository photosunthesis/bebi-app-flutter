import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';

class ShakeOnTap extends StatefulWidget {
  const ShakeOnTap({required this.child, required this.shouldShake, super.key});
  final Widget child;
  final bool shouldShake;
  @override
  State<ShakeOnTap> createState() => _ShakeOnTapState();
}

class _ShakeOnTapState extends State<ShakeOnTap>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: 300.milliseconds,
  );
  late final _offsetAnimation = Tween(
    begin: Offset.zero,
    end: const Offset(0.1, 0),
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticIn));

  void _handleTap() {
    if (widget.shouldShake && !_controller.isAnimating) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: SlideTransition(position: _offsetAnimation, child: widget.child),
    );
  }
}
