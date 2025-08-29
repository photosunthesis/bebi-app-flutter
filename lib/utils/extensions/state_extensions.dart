import 'package:bebi_app/utils/extensions/widgets_binding_extensions.dart';
import 'package:flutter/material.dart';

extension StateExtensions on State {
  /// Runs [stateChange] within setState() as early as possible.
  ///
  /// Defers to next frame if called during build phase, otherwise runs immediately.
  ///
  /// Adapted from Super Editor's `flutter_scheduler.dart`
  /// Source: https://github.com/superlistapp/super_editor/blob/main/super_editor/lib/src/infrastructure/flutter/flutter_scheduler.dart
  void setStateAsSoonAsPossible(VoidCallback stateChange) {
    WidgetsBinding.instance.runAsSoonAsPossible(() {
      if (!mounted) return;
      // ignore: invalid_use_of_protected_member
      setState(() => stateChange());
    });
  }
}
