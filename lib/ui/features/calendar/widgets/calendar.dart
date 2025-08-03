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
        return TableCalendar<CalendarEvent>(
          eventLoader: (day) => state.events,
          headerVisible: false,
          focusedDay: state.focusedDay,
          currentDay: DateTime.now(),
          firstDay: DateTime.now().subtract(2.years),
          lastDay: DateTime.now().add(2.years),
          selectedDayPredicate: (day) => day.isSameDay(state.focusedDay),
          daysOfWeekHeight: 32,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const <CalendarFormat, String>{
            CalendarFormat.month: 'Month',
          },
          daysOfWeekStyle: _dayOfWeekStyle(context),
          calendarStyle: _calendarStyle(context),
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
      margin: const EdgeInsets.fromLTRB(15, 10, 15, 18),
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: UiConstants.borderRadius,
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
      margin: const EdgeInsets.fromLTRB(15, 10, 15, 18),
      decoration: BoxDecoration(
        color: day.isSameDay(focusedDay) ? context.colorScheme.primary : null,
        borderRadius: UiConstants.borderRadius,
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
      margin: const EdgeInsets.fromLTRB(15, 10, 15, 18),
      decoration: const BoxDecoration(borderRadius: UiConstants.borderRadius),
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
      margin: const EdgeInsets.fromLTRB(15, 10, 15, 18),
      decoration: const BoxDecoration(borderRadius: UiConstants.borderRadius),
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
    final dayColors = dayEvents.map((e) => e.color).toSet();

    return Opacity(
      opacity: day.isSameMonth(focusedDay) ? 1 : 0.4,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...dayColors
                .take(3)
                .map(
                  (color) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            if (dayColors.length > 3)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: dayColors.last.withAlpha(100),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayOfWeek(BuildContext context, DateTime day) {
    return Center(
      child: Text(
        day.weekDayInitial,
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
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
            width: 0.2,
          ),
        ),
      ),
    );
  }

  CalendarStyle _calendarStyle(BuildContext context) {
    return CalendarStyle(
      rowDecoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.onSecondary,
            // Weird bug with the border on different platforms 🤷🏻
            width: UiConstants.borderWidth,
          ),
        ),
      ),
    );
  }
}
