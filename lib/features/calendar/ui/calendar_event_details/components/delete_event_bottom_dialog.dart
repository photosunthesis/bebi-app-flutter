import 'package:bebi_app/core/ui/options_bottom_dialog.dart';
import 'package:bebi_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:bebi_app/features/calendar/ui/save_changes_dialog_options.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:material_ui/material_ui.dart';

Future<SaveChangesDialogOptions?> showDeleteEventBottomDialog(
  BuildContext context,
  CalendarEvent calendarEvent,
) {
  return OptionsBottomDialog.show(
    context,
    title: context.l10n.deleteEventTitle,
    description: calendarEvent.isRecurring
        ? context.l10n.deleteRecurringEventMessage
        : context.l10n.deleteEventMessage,
    options: [
      Option(
        text: context.l10n.deleteThisEvent,
        value: SaveChangesDialogOptions.onlyThisEvent,
        style: OptionStyle.destructive,
      ),
      if (calendarEvent.isRecurring && !calendarEvent.isLastRecurringEvent)
        Option(
          text: context.l10n.deleteThisAndFutureEvents,
          value: SaveChangesDialogOptions.allFutureEvents,
          style: OptionStyle.destructive,
        ),
      Option(
        text: context.l10n.cancelButton,
        value: SaveChangesDialogOptions.cancel,
      ),
    ],
  );
}
