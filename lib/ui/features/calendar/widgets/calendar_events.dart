import 'dart:math';

import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/kaomojis.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 8, top: index == 0 ? 10 : 4),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildColorBar(event.eventColor.color),
            const SizedBox(width: 8),
            Expanded(child: _buildEventDetails(context, event)),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildColorBar(Color color) {
    return Container(
      width: 4,
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
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
    return Expanded(
      child: Text(
        title,
        style: context.primaryTextTheme.titleLarge?.copyWith(
          color: context.colorScheme.primary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEventTime(CalendarEvent event, bool allDay, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Expanded(
        child: Text(
          allDay
              ? 'All day'
              : _formatDuration(event.startTimeLocal, event.endTimeLocal),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEventLocation(String location, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Expanded(
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
