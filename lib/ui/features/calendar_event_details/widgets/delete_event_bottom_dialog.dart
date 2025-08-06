import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:flutter/material.dart';

enum DeleteEventResult { deleteThisEvent, deleteFutureEvents, cancel }

Future<DeleteEventResult?> showDeleteEventBottomDialog(
  BuildContext context,
  CalendarEvent calendarEvent,
) {
  return OptionsBottomDialog.show(
    context,
    title: 'Delete event?',
    description: calendarEvent.isRecurring
        ? 'Do you want to delete just this event or include all future events? This cannot be undone.'
        : 'Do you want to delete this event? This action cannot be undone.',
    options: [
      const Option(
        text: 'Delete this event',
        value: DeleteEventResult.deleteThisEvent,
        style: OptionStyle.destructive,
      ),
      if (calendarEvent.isRecurring && !calendarEvent.isLastRecurringEvent)
        const Option(
          text: 'Delete this and future events',
          value: DeleteEventResult.deleteFutureEvents,
          style: OptionStyle.destructive,
        ),
      const Option(
        text: 'Cancel',
        value: DeleteEventResult.cancel,
        style: OptionStyle.secondary,
      ),
    ],
  );
}
