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
          headerVisible: false,
          focusedDay: state.focusedDay,
          currentDay: DateTime.now(),
          firstDay: DateTime.now().subtract(2.years),
          lastDay: DateTime.now().add(2.years),
          selectedDayPredicate: (day) => day.isSameDay(state.focusedDay),
          daysOfWeekHeight: 32,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          daysOfWeekStyle: _dayOfWeekStyle(context),
          calendarStyle: _calendarStyle(context),
          calendarBuilders: CalendarBuilders(
            selectedBuilder: _selectedDayBuilder,
            todayBuilder: _todayBuilder,
            dowBuilder: _buildDayOfWeek,
            defaultBuilder: _defaultDayBuilder,
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
      margin: const EdgeInsets.all(13),
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
      margin: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: day.isSameDay(focusedDay) ? context.colorScheme.primary : null,
        shape: BoxShape.circle,
        border: Border.all(color: context.colorScheme.primary, width: 0.6),
      ),
      child: Center(
        child: Text(
          day.day.toString(),
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: day.isSameDay(focusedDay)
                ? context.colorScheme.onPrimary
                : context.colorScheme.onSurface,
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
      margin: const EdgeInsets.all(13),
      decoration: const BoxDecoration(shape: BoxShape.circle),
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
            width: 0.15,
          ),
        ),
      ),
    );
  }
}
