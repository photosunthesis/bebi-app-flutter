import 'dart:async';

import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AppDateTimePicker extends StatefulWidget {
  const AppDateTimePicker({
    required this.label,
    required this.value,
    required this.onChanged,
    this.allDay = false,
    this.minDate,
    this.maxDate,
    super.key,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool allDay;
  final DateTime? minDate;
  final DateTime? maxDate;

  @override
  State<AppDateTimePicker> createState() => _AppDateTimePickerState();
}

class _AppDateTimePickerState extends State<AppDateTimePicker> {
  late DateTime _selectedDate = widget.value;
  bool _showCalendarPicker = false;
  bool _showTimePicker = false;
  Timer? _timePickerTimer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(widget.label, style: context.textTheme.bodyMedium),
              const Spacer(),
              InkWell(
                onTap: () => setState(() {
                  if (_showTimePicker) _showTimePicker = false;
                  _showCalendarPicker = !_showCalendarPicker;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.secondary.withAlpha(32),
                    borderRadius: UiConstants.borderRadius,
                  ),
                  child: Text(
                    _selectedDate.toMMMdyyyy(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (!widget.allDay) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => setState(() {
                    if (_showCalendarPicker) _showCalendarPicker = false;
                    _showTimePicker = !_showTimePicker;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.secondary.withAlpha(32),
                      borderRadius: UiConstants.borderRadius,
                    ),
                    child: Text(
                      _selectedDate.toHHmma(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],

              AnimatedContainer(
                duration: 300.milliseconds,
                child: AnimatedOpacity(
                  opacity: _showCalendarPicker ? 1 : 0,
                  duration: 300.milliseconds,
                  child: _showCalendarPicker
                      ? _buildCalendar()
                      : const SizedBox.shrink(key: Key('hidden-calendar')),
                ),
              ),
              AnimatedContainer(
                duration: 300.milliseconds,
                child: AnimatedOpacity(
                  opacity: _showTimePicker ? 1 : 0,
                  duration: 300.milliseconds,
                  child: _showTimePicker
                      ? _buildTimePicker()
                      : const SizedBox.shrink(key: Key('hidden-time')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      key: const Key('calendar'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UiConstants.borderRadiusValue),
        border: Border.all(
          color: context.colorScheme.outline,
          width: UiConstants.borderWidth,
        ),
      ),
      child: TableCalendar(
        availableGestures: AvailableGestures.horizontalSwipe,
        shouldFillViewport: true,
        enabledDayPredicate: (day) {
          if (widget.minDate != null) {
            // Check if day is before minDate
            if (day.isBefore(widget.minDate!) &&
                !day.isSameDay(widget.minDate!)) {
              return false;
            }
          }

          if (widget.maxDate != null) {
            // Check if day is after maxDate
            if (day.isAfter(widget.maxDate!) &&
                !day.isSameDay(widget.maxDate!)) {
              return false;
            }
          }

          return true;
        },
        headerVisible: false,
        focusedDay: _selectedDate,
        currentDay: DateTime.now(),
        firstDay: widget.minDate ?? DateTime.now().subtract(365.days),
        lastDay: widget.maxDate ?? DateTime.now().add(365.days),
        selectedDayPredicate: _selectedDate.isSameDay,
        daysOfWeekHeight: 32,
        calendarBuilders: CalendarBuilders(
          selectedBuilder: (context, day, focusedDay) =>
              _buildDayCell(context, day, focusedDay, isSelected: true),
          todayBuilder: (context, day, focusedDay) =>
              _buildDayCell(context, day, focusedDay, isToday: true),
          dowBuilder: _buildDayOfWeek,
          defaultBuilder: (context, day, focusedDay) =>
              _buildDayCell(context, day, focusedDay),
          disabledBuilder: (context, day, focusedDay) =>
              _buildDayCell(context, day, focusedDay, isDisabled: true),
          outsideBuilder: (context, day, focusedDay) =>
              _buildDayCell(context, day, focusedDay, isDisabled: true),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.outline,
                width: UiConstants.borderWidth,
              ),
            ),
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          final date = DateTime(
            selectedDay.year,
            selectedDay.month,
            selectedDay.day,
            _selectedDate.hour,
            _selectedDate.minute,
          );
          widget.onChanged(date);
          setState(() {
            _selectedDate = date;
            _showCalendarPicker = false;
          });
        },
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    DateTime focusedDay, {
    bool isSelected = false,
    bool isToday = false,
    bool isDisabled = false,
  }) {
    BoxDecoration? decoration;
    Color textColor;

    if (isSelected) {
      decoration = BoxDecoration(
        color: context.colorScheme.primary,
        shape: BoxShape.circle,
      );
      textColor = context.colorScheme.onPrimary;
    } else if (isToday) {
      decoration = BoxDecoration(
        color: day.isSameDay(focusedDay) ? context.colorScheme.primary : null,
        border: Border.all(color: context.colorScheme.primary, width: 0.6),
        shape: BoxShape.circle,
      );
      textColor = day.isSameDay(focusedDay)
          ? context.colorScheme.onPrimary
          : context.colorScheme.onSurface;
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
        margin: const EdgeInsets.all(5),
        decoration: decoration,
        child: Center(
          child: Opacity(
            opacity: isDisabled ? 0.2 : 1,
            child: Text(
              day.day.toString(),
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayOfWeek(BuildContext context, DateTime day) {
    return Center(
      child: Text(
        day.weekDayInitial,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return SizedBox(
      key: const Key('time'),
      height: 160,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: _selectedDate,
        minimumDate: widget.minDate,
        maximumDate: widget.maxDate,
        selectionOverlayBuilder:
            (context, {required columnCount, required selectedIndex}) {
              final isFirstColumn = selectedIndex == 0;
              final isLastColumn = selectedIndex == columnCount - 1;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: isFirstColumn
                        ? const Radius.circular(UiConstants.borderRadiusValue)
                        : Radius.zero,
                    bottomLeft: isFirstColumn
                        ? const Radius.circular(UiConstants.borderRadiusValue)
                        : Radius.zero,
                    topRight: isLastColumn
                        ? const Radius.circular(UiConstants.borderRadiusValue)
                        : Radius.zero,
                    bottomRight: isLastColumn
                        ? const Radius.circular(UiConstants.borderRadiusValue)
                        : Radius.zero,
                  ),
                  color: context.colorScheme.onSurface.withAlpha(20),
                ),
              );
            },
        onDateTimeChanged: (newDate) {
          final date = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            newDate.hour,
            newDate.minute,
          );
          widget.onChanged(date);
          setState(() => _selectedDate = date);
          _timePickerTimer?.cancel();
          _timePickerTimer = Timer(
            3.seconds,
            () => setState(() => _showTimePicker = false),
          );
        },
      ),
    );
  }
}
