import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:super_editor/super_editor.dart';

extension WidgetsBindingExtensions on WidgetsBinding {
  /// Safely executes [action] to prevent setState crashes during build phases.
  ///
  /// Runs immediately if outside build phase, otherwise defers to post-frame callback.
  ///
  /// Adapted from Super Editor's `flutter_scheduler.dart`
  /// Source: https://github.com/superlistapp/super_editor/blob/main/super_editor/lib/src/infrastructure/flutter/flutter_scheduler.dart
  void runAsSoonAsPossible(
    VoidCallback action, {
    String debugLabel = 'anonymous action',
  }) {
    schedulerLog.info("Running action as soon as possible: '$debugLabel'.");
    if (schedulerPhase == SchedulerPhase.persistentCallbacks) {
      // The Flutter pipeline is in the middle of a build phase. Schedule the desired
      // action for the end of the current frame.
      schedulerLog.info(
        "Scheduling another frame to run '$debugLabel' because Flutter is building widgets right now.",
      );
      addPostFrameCallback((timeStamp) {
        schedulerLog.info(
          "Flutter is done building widgets. Running '$debugLabel' at the end of the frame.",
        );
        action();
      });
    } else {
      // The Flutter pipeline isn't building widgets right now. Execute the action
      // immediately.
      schedulerLog.info(
        "Flutter isn't building widgets right now. Running '$debugLabel' immediately.",
      );
      action();
    }
  }
}
