import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/ui/features/calendar/calendar_cubit.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

class Calendar extends StatelessWidget {
  const Calendar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: context.colorScheme.outline,
                width: UiConstants.borderWidth,
              ),
              bottom: BorderSide(
                color: context.colorScheme.outline,
                width: UiConstants.borderWidth,
              ),
            ),
          ),
          child: TableCalendar<CalendarEvent>(
            eventLoader: (day) => state.events,
            headerVisible: false,
            focusedDay: state.focusedDay,
            currentDay: DateTime.now(),
            firstDay: DateTime.now().subtract(2.years),
            lastDay: DateTime.now().add(2.years),
            selectedDayPredicate: (day) => day.isSameDay(state.focusedDay),
            daysOfWeekHeight: 32,
            // TODO Add feature to switch to week view
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: {
              CalendarFormat.month: 'Month',
              CalendarFormat.week: 'Week',
            },
            daysOfWeekStyle: _dayOfWeekStyle(context),
            calendarBuilders: CalendarBuilders(
              selectedBuilder: _selectedDayBuilder,
              todayBuilder: _todayBuilder,
              dowBuilder: _buildDayOfWeek,
              defaultBuilder: _defaultDayBuilder,
              outsideBuilder: _outsideBuilder,
              markerBuilder: (context, day, events) =>
                  _markerBuilder(context, day, events, state.focusedDay),
            ),
            onDaySelected: (day, _) {
              context.read<CalendarCubit>().setFocusedDay(day);
            },
            onPageChanged: (focusedDay) {
              context.read<CalendarCubit>().setFocusedDay(
                DateTime.now().isSameMonth(focusedDay)
                    ? DateTime.now()
                    : focusedDay,
              );
            },
          ),
        );
      },
    );
  }

  Widget _selectedDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          day.day.toString(),
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _todayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      decoration: BoxDecoration(
        color: day.isSameDay(focusedDay) ? context.colorScheme.primary : null,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colorScheme.primary.withAlpha(
            day.isSameMonth(focusedDay) ? 255 : 80,
          ),
          width: 0.6,
        ),
      ),
      child: Center(
        child: Text(
          day.day.toString(),
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: day.isSameDay(focusedDay)
                ? context.colorScheme.onPrimary
                : day.isSameMonth(focusedDay)
                ? context.colorScheme.onSurface
                : context.colorScheme.onSurface.withAlpha(80),
          ),
        ),
      ),
    );
  }

  Widget _defaultDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: Center(
        child: Text(
          day.day.toString(),
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _outsideBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      child: Center(
        child: Text(
          day.day.toString(),
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onSurface.withAlpha(80),
          ),
        ),
      ),
    );
  }

  Widget _markerBuilder(
    BuildContext context,
    DateTime day,
    List<CalendarEvent> events,
    DateTime focusedDay,
  ) {
    final dayEvents = events.where((e) => e.dateLocal.isSameDay(day)).toList();

    if (dayEvents.isEmpty) return const SizedBox.shrink();

    final colorCounts = <Color, int>{};
    for (final event in dayEvents) {
      colorCounts[event.color] = (colorCounts[event.color] ?? 0) + 1;
    }

    final totalEvents = dayEvents.length;
    final colorSegments = colorCounts.entries.toList();

    final baseWidth = 8.0;
    final maxWidth = 24.0;
    final width = (baseWidth + (totalEvents - 1) * 4).clamp(
      baseWidth,
      maxWidth,
    );

    return Opacity(
      opacity: day.isSameMonth(focusedDay) ? 1 : 0.4,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          width: width,
          height: 6,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Row(
              children: colorSegments.map((entry) {
                final proportion = entry.value / totalEvents;
                return Expanded(
                  flex: (proportion * 100).round(),
                  child: Container(color: entry.key),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayOfWeek(BuildContext context, DateTime day) {
    return Center(
      child: Text(
        day.toEEE(),
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: context.colorScheme.onSurface,
        ),
      ),
    );
  }

  DaysOfWeekStyle _dayOfWeekStyle(BuildContext context) {
    return DaysOfWeekStyle(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.onSecondary,
            width: UiConstants.borderWidth,
          ),
        ),
      ),
    );
  }
}
