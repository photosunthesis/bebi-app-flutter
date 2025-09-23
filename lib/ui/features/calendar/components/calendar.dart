import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/ui/features/calendar/calendar_cubit.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
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
            color: context.colorScheme.surface,
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
            availableGestures: AvailableGestures.horizontalSwipe,
            focusedDay: state.focusedDay,
            eventLoader: (day) => state.events.maybeMap(
              data: (events) => events,
              orElse: () => <CalendarEvent>[],
            ),
            sixWeekMonthsEnforced: true,
            headerVisible: false,
            currentDay: DateTime.now(),
            // TODO Make first and last days dynamic
            firstDay: DateTime.now().subtract(2.years),
            lastDay: DateTime.now().add(2.years),
            selectedDayPredicate: (day) => day.isSameDay(state.focusedDay),
            daysOfWeekHeight: 32,
            availableCalendarFormats: {
              CalendarFormat.month: context.l10n.monthFormat,
            },
            daysOfWeekStyle: _dayOfWeekStyle(context),
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day, focusedDay, isSelected: true),
              todayBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day, focusedDay, isToday: true),
              dowBuilder: _buildDayOfWeek,
              defaultBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day, focusedDay),
              outsideBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day, focusedDay, isOutside: true),
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

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    DateTime focusedDay, {
    bool isSelected = false,
    bool isToday = false,
    bool isOutside = false,
  }) {
    final isSameMonth = day.isSameMonth(focusedDay);

    Color textColor;
    BoxDecoration? decoration;

    if (isSelected) {
      textColor = context.colorScheme.onPrimary;
      decoration = BoxDecoration(
        color: context.colorScheme.primary,
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      textColor = isSameMonth
          ? context.colorScheme.onSurface
          : context.colorScheme.onSurface.withAlpha(80);
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colorScheme.primary.withAlpha(isSameMonth ? 255 : 80),
          width: 0.6,
        ),
      );
    } else if (isOutside) {
      textColor = context.colorScheme.onSurface.withAlpha(80);
    } else {
      textColor = context.colorScheme.onSurface;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outline,
            width: UiConstants.borderWidth,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 18),
        decoration: decoration,
        child: Center(
          child: Text(
            day.day.toString(),
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _markerBuilder(
    BuildContext context,
    DateTime day,
    List<CalendarEvent> events,
    DateTime? focusedDay,
  ) {
    final dayEvents = events.where((e) => e.startDate.isSameDay(day)).toList();

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
      opacity: focusedDay != null && day.isSameMonth(focusedDay) ? 1 : 0.4,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          width: width,
          height: 6,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
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
