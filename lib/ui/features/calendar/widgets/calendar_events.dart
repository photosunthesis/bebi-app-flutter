import 'dart:math';

import 'package:bebi_app/constants/kaomojis.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/ui/features/calendar/calendar_cubit.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalendarEvents extends StatefulWidget {
  const CalendarEvents({super.key});

  @override
  State<CalendarEvents> createState() => _CalendarEventsState();
}

class _CalendarEventsState extends State<CalendarEvents> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        if (state.focusedDayEvents.isEmpty) {
          return _buildNoEventsPlaceholder(state.focusedDay);
        }

        return ListView.builder(
          itemCount: state.focusedDayEvents.length,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  _buildTitle(context, state.focusedDay),
                  const SizedBox(height: 10),
                  _buildEventCard(context, state.focusedDayEvents[index]),
                ],
              );
            }

            return _buildEventCard(context, state.focusedDayEvents[index]);
          },
        );
      },
    );
  }

  Widget _buildNoEventsPlaceholder(DateTime focusedDay) {
    final kaomoji =
        Kaomojis.happySet[Random().nextInt(Kaomojis.happySet.length)];

    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 14),
            child: _buildTitle(context, focusedDay),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kaomoji,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontSize: 30,
                      color: context.colorScheme.secondary.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No events for this day',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context, DateTime focusedDay) {
    return Text(
      (focusedDay.isToday
              ? 'Today, ${focusedDay.toEEEEMMMMd()}'
              : focusedDay.toEEEEMMMMd())
          .toUpperCase(),
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colorScheme.secondary,
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
    return Container(width: 4, decoration: BoxDecoration(color: event.color));
  }

  String _duration(DateTime start, DateTime? end, {bool isAllDay = false}) {
    if (isAllDay) return 'All day';
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
        Text(
          event.title,
          style: context.primaryTextTheme.titleLarge?.copyWith(),
        ),
        const SizedBox(height: 6),
        if (event.notes != null && event.notes!.isNotEmpty) ...[
          Text(
            event.notes!,
            style: context.textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Text(
              _duration(event.startDate, event.endDate, isAllDay: event.allDay),
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.location ?? '',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
