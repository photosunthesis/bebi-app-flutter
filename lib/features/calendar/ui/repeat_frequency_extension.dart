import 'package:bebi_app/features/calendar/domain/entities/repeat_rule.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:material_ui/material_ui.dart';

extension RepeatFrequencyExtension on RepeatFrequency {
  String label(BuildContext context) => switch (this) {
    RepeatFrequency.daily => context.l10n.repeatDaily,
    RepeatFrequency.weekly => context.l10n.repeatWeekly,
    RepeatFrequency.monthly => context.l10n.repeatMonthly,
    RepeatFrequency.yearly => context.l10n.repeatYearly,
    RepeatFrequency.doNotRepeat => context.l10n.repeatDoNotRepeat,
  };
}
