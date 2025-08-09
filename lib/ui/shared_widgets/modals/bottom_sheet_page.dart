import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/material.dart';

class BottomSheetPage<T> extends Page<T> {
  const BottomSheetPage(this.child);

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    useSafeArea: true,
    isScrollControlled: true,
    modalBarrierColor: context.colorScheme.primary.withAlpha(40),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (context) =>
        (ModalRoute.of(context)?.settings as BottomSheetPage<T>).child,
  );
}
