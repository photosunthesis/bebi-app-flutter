import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';

class BottomSheetPage<T> extends Page<T> {
  const BottomSheetPage({required this.child, this.isScrollControlled = true});

  final Widget child;
  final bool isScrollControlled;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    useSafeArea: true,
    isScrollControlled: isScrollControlled,
    modalBarrierColor: context.colorScheme.primary.withAlpha(80),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (context) =>
        (ModalRoute.of(context)?.settings as BottomSheetPage<T>).child,
  );
}
