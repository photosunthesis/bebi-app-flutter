import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/kaomojis.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:flutter/material.dart';

abstract class CalendarEvents {
  static final _kaomoji = Kaomojis.getRandomFromHappySet();

  static SliverList buildList(List<CalendarEvent> events) {
    return SliverList.builder(
      itemCount: events.length,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 8, top: index == 0 ? 10 : 4),
        child: _EventCard(event: events[index]),
      ),
    );
  }

  static SliverFillRemaining buildEmptyPlaceholder(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      fillOverscroll: true,
      child: Center(
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
              context.l10n.noEventsText,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.secondary.withAlpha(80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async => context.pushNamed(
        AppRoutes.viewCalendarEvent,
        extra: event,
        pathParameters: {'id': event.id},
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: event.color.withAlpha(50),
          borderRadius: UiConstants.borderRadius,
          border: Border.all(
            color: event.color.darken(0.2),
            width: UiConstants.borderWidth,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: event.color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3 + 8),
              child: _buildEventDetails(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(BuildContext context, DateTime start, DateTime? end) {
    final startTime = TimeOfDay.fromDateTime(start);
    final endTime = end != null ? TimeOfDay.fromDateTime(end) : null;
    final startStr = startTime.format(context);
    final endStr = endTime != null ? endTime.format(context) : '';
    return endStr.isNotEmpty ? '$startStr → $endStr' : startStr;
  }

  Widget _buildEventDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(context),
        const SizedBox(height: 4),
        _buildTime(context),
        if (event.notes != null && event.notes!.isNotEmpty) ...[
          const SizedBox(height: 3),
          _buildNotes(context),
        ],
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      event.title,
      style: context.primaryTextTheme.titleLarge?.copyWith(
        color: event.color.darken(0.3),
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTime(BuildContext context) {
    return Text(
      event.allDay
          ? context.l10n.allDayText.toUpperCase()
          : _formatDuration(context, event.startTimeLocal, event.endTimeLocal),
      style: context.textTheme.bodySmall?.copyWith(
        color: event.color.darken(0.1),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildNotes(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Text(
        event.notes!,
        style: context.textTheme.bodyMedium?.copyWith(
          color: event.color.darken(0.1),
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}
