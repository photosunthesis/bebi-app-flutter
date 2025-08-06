import 'dart:math';

import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/kaomojis.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/ui/features/calendar/calendar_cubit.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
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
            duration: 120.milliseconds,
            reverseDuration: 0.milliseconds,
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuint,
                ),
                axisAlignment: -1.0,
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(
                        0.0,
                        0.6,
                        curve: Curves.easeInQuint,
                      ),
                    ),
                  ),
                  child: child,
                ),
              );
            },
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
      key: ValueKey(events),
      itemCount: events.length,
      padding: const EdgeInsets.all(18),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildEventCard(context, events[index]),
      ),
    );
  }

  Widget _buildNoEventsPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _kaomoji,
            style: context.textTheme.titleLarge?.copyWith(
              color: context.colorScheme.secondary.withAlpha(80),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No events',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.secondary.withAlpha(80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    return IntrinsicHeight(
      child: InkWell(
        onTap: () async => context.pushNamed(
          AppRoutes.viewCalendarEvent,
          extra: event,
          pathParameters: {'id': event.id},
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: event.eventColor.color.withAlpha(40),
            borderRadius: UiConstants.borderRadius,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: 8),
              _buildColorBar(event.eventColor.color),
              const SizedBox(width: 8),
              Expanded(child: _buildEventDetails(context, event)),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorBar(Color color) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: color,
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
        _buildEventTitle(event.title, event.eventColor.color),
        _buildEventTime(event, event.allDay, event.eventColor.color),
        if (event.location != null && event.location!.isNotEmpty)
          _buildEventLocation(event.location!, event.eventColor.color),
      ],
    );
  }

  Widget _buildEventTitle(String title, Color color) {
    return Text(
      title,
      style: context.primaryTextTheme.titleLarge?.copyWith(
        color: color.darken(0.3),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventTime(CalendarEvent event, bool allDay, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        allDay
            ? 'All day'
            : _formatDuration(event.startTimeLocal, event.endTimeLocal),
        style: context.textTheme.bodyMedium?.copyWith(color: color.darken(0.3)),
      ),
    );
  }

  Widget _buildEventLocation(String location, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          location,
          style: context.textTheme.bodyMedium?.copyWith(
            color: color.darken(0.3),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
