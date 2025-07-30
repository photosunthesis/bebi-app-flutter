import 'dart:math';

import 'package:bebi_app/constants/kaomojis.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/ui/features/calendar/calendar_cubit.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalendarEvents extends StatefulWidget {
  const CalendarEvents({super.key});

  @override
  State<CalendarEvents> createState() => _CalendarEventsState();
}

class _CalendarEventsState extends State<CalendarEvents> {
  final _kaomoji =
      Kaomojis.happySet[Random().nextInt(Kaomojis.happySet.length)];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocSelector<CalendarCubit, CalendarState, List<CalendarEvent>>(
        selector: (state) => state.focusedDayEvents,
        builder: (context, events) {
          return AnimatedSwitcher(
            duration: 300.milliseconds,
            child: events.isEmpty
                ? _buildNoEventsPlaceholder()
                : _buildEventsList(events),
          );
        },
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events) {
    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemBuilder: (context, index) => _buildEventCard(context, events[index]),
    );
  }

  Widget _buildNoEventsPlaceholder() {
    return Center(
      child: Text(
        _kaomoji,
        style: context.textTheme.headlineSmall?.copyWith(
          fontSize: 30,
          color: context.colorScheme.secondary.withAlpha(80),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: event.color.withAlpha(40),
          borderRadius: UiConstants.borderRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 8),
            _buildColorBar(event),
            const SizedBox(width: 8),
            Expanded(child: _buildEventDetails(context, event)),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildColorBar(CalendarEvent event) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: event.color,
        borderRadius: UiConstants.borderRadius,
      ),
    );
  }

  String _formatDuration(DateTime start, DateTime? end) {
    final startTime = TimeOfDay.fromDateTime(start);
    final endTime = end != null ? TimeOfDay.fromDateTime(end) : null;
    final startStr = startTime.format(context);
    final endStr = endTime != null ? endTime.format(context) : '';
    return endStr.isNotEmpty ? '$startStr → $endStr' : startStr;
  }

  Widget _buildEventDetails(BuildContext context, CalendarEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventTitle(event),
        _buildEventTime(event, allDay: event.allDay),
        if (event.location != null && event.location!.isNotEmpty)
          _buildEventLocation(event.location!),
      ],
    );
  }

  Widget _buildEventTitle(CalendarEvent event) {
    return Text(
      event.title,
      style: context.primaryTextTheme.titleLarge,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventTime(CalendarEvent event, {required bool allDay}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        allDay ? 'All day' : _formatDuration(event.startTime, event.endTime),
        style: context.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildEventLocation(String location) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          location,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.secondary,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
