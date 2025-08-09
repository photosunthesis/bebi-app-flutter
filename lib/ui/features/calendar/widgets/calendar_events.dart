import 'dart:math';

import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/kaomojis.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/ui/features/calendar/calendar_cubit.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: event.color.withAlpha(50),
            borderRadius: UiConstants.borderRadius,
            border: Border.all(
              color: event.color.darken(0.2),
              width: UiConstants.borderWidth,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // _buildColorBar(event.color),
              // const SizedBox(width: 8),
              Expanded(child: _buildEventDetails(context, event)),
              // const SizedBox(width: 12),
            ],
          ),
        ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventTitle(event.title, event.color),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildEventTime(event, event.allDay, event.color),
                    if (event.notes != null && event.notes!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildEventLocation(event.notes!, event.color),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildAccountsSection(event),
      ],
    );
  }

  Widget _buildAccountsSection(CalendarEvent event) {
    return BlocSelector<
      CalendarCubit,
      CalendarState,
      (UserProfile?, UserProfile?)
    >(
      selector: (state) => (state.userProfile, state.partnerProfile),
      builder: (context, accounts) {
        final sharedWithPartner = event.users.contains(accounts.$2?.userId);
        return SizedBox(
          width: 46,
          child: Stack(
            children: [
              if (sharedWithPartner && accounts.$2 != null)
                Opacity(
                  opacity: 0.6,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage: CachedNetworkImageProvider(
                        accounts.$2!.photoUrl!,
                      ),
                      radius: 14,
                    ),
                  ),
                ),
              if (accounts.$1 != null)
                Padding(
                  padding: EdgeInsets.only(left: sharedWithPartner ? 0 : 18),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage: CachedNetworkImageProvider(
                      accounts.$1!.photoUrl!,
                    ),
                    radius: 14,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventTitle(String title, Color color) {
    return Text(
      title,
      style: context.textTheme.titleMedium?.copyWith(
        color: color.darken(0.3),
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventTime(CalendarEvent event, bool allDay, Color color) {
    return Text(
      allDay
          ? 'All-day'.toUpperCase()
          : _formatDuration(event.startTimeLocal, event.endTimeLocal),
      style: context.textTheme.bodySmall?.copyWith(
        color: color.darken(0.1),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildEventLocation(String location, Color color) {
    return Text(
      location,
      style: context.textTheme.bodyMedium?.copyWith(color: color.darken(0.1)),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
