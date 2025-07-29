import 'package:bebi_app/constants/ui_constants.dart';
import 'package:flutter/material.dart';

class BottomSheetPage<T> extends Page<T> {
  const BottomSheetPage(this.child);

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => ModalBottomSheetRoute<T>(
    settings: this,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(UiConstants.borderRadiusLargeValue),
      ),
    ),
    builder: (context) =>
        (ModalRoute.of(context)?.settings as BottomSheetPage<T>).child,
  );
}
