import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/features/calendar/domain/calendar_event.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:material_ui/material_ui.dart';

extension EventColorExtension on EventColor {
  Color get color => switch (this) {
    EventColor.black => AppColors.stone600,
    EventColor.green => AppColors.green,
    EventColor.blue => AppColors.blue,
    EventColor.yellow => AppColors.yellow,
    EventColor.pink => AppColors.pink,
    EventColor.orange => AppColors.orange,
    EventColor.red => AppColors.red,
  };

  String label(BuildContext context) => switch (this) {
    EventColor.black => context.l10n.eventColorBlack,
    EventColor.green => context.l10n.eventColorGreen,
    EventColor.blue => context.l10n.eventColorBlue,
    EventColor.yellow => context.l10n.eventColorYellow,
    EventColor.pink => context.l10n.eventColorPink,
    EventColor.orange => context.l10n.eventColorOrange,
    EventColor.red => context.l10n.eventColorRed,
  };
}

extension CalendarEventColorExtension on CalendarEvent {
  Color get color => eventColor.color;
}
