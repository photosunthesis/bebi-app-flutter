import 'package:flutter/material.dart';

class BottomSheetPage<T> extends Page<T> {
  const BottomSheetPage(this.child);

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (context) =>
        (ModalRoute.of(context)?.settings as BottomSheetPage<T>).child,
  );
}
