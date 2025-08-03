import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum DeleteEventResult { deleteThisEvent, deleteFutureEvents, cancel }

class DeleteEventBottomDialog extends StatelessWidget {
  const DeleteEventBottomDialog(this.calendarEvent, {super.key});

  final CalendarEvent calendarEvent;

  static Future<DeleteEventResult?> show(
    BuildContext context,
    CalendarEvent calendarEvent,
  ) {
    return showModalBottomSheet<DeleteEventResult>(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => DeleteEventBottomDialog(calendarEvent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(UiConstants.borderRadiusLargeValue),
          topRight: Radius.circular(UiConstants.borderRadiusLargeValue),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UiConstants.padding,
            ),
            child: Text(
              'Delete event?',
              style: context.primaryTextTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UiConstants.padding,
            ),
            child: Text(
              calendarEvent.isRecurring
                  ? 'Do you want to delete just this event or include all future events? This cannot be undone.'
                  : 'Do you want to delete this event? This action cannot be undone.',
              style: context.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          _buildOption(
            context,
            'Delete this event',
            DeleteEventResult.deleteThisEvent,
          ),
          if (calendarEvent.isRecurring && !calendarEvent.isLastRecurringEvent)
            _buildOption(
              context,
              'Delete this and future events',
              DeleteEventResult.deleteFutureEvents,
            ),
          _buildOption(context, 'Cancel', DeleteEventResult.cancel),
          const SafeArea(child: SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    String text,
    DeleteEventResult result,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UiConstants.padding,
        vertical: 2,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colorScheme.surface,
          foregroundColor: result == DeleteEventResult.cancel
              ? context.colorScheme.primary
              : context.colorScheme.error.darken(0.04),
          side: BorderSide(
            color: context.colorScheme.primary,
            width: UiConstants.borderWidth,
          ),
        ),
        onPressed: () => context.pop(result),
        child: Text(text),
      ),
    );
  }
}
