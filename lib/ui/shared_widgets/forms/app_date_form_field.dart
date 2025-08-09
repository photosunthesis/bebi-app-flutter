import 'dart:async';

import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AppDateFormField extends StatefulWidget {
  const AppDateFormField({
    super.key,
    this.controller,
    this.hintText,
    this.minimumDate,
    this.maximumDate,
    this.focusedDay,
    this.validator,
  });

  final TextEditingController? controller;
  final String? hintText;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final DateTime? focusedDay;
  final String? Function(String?)? validator;

  @override
  State<AppDateFormField> createState() => _AppDateFormFieldState();
}

class _AppDateFormFieldState extends State<AppDateFormField> {
  late final _controller = widget.controller ?? TextEditingController();
  late DateTime _focusedDay = widget.focusedDay ?? DateTime.now();
  DateTime? _selectedDay;
  bool _showCalendar = false;
  Timer? _blinkTimer;
  bool _isBlinkingPrimary = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusedDay != null) {
      _selectedDay = widget.focusedDay;
      _updateControllerText();
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onDateSelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _showCalendar = false;
      _updateControllerText();
    });

    _stopBlinking();
  }

  void _startBlinking() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(400.milliseconds, (timer) {
      setState(() => _isBlinkingPrimary = !_isBlinkingPrimary);
    });
  }

  void _stopBlinking() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    setState(() {
      _isBlinkingPrimary = false;
    });
  }

  void _updateControllerText() {
    if (_selectedDay != null) {
      final dateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );

      _controller.text = dateTime.toEEEEMMMdyyyy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 120.milliseconds,
      curve: Curves.easeOutCirc,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildTextFormField(), _buildPickerContainer()],
      ),
    );
  }

  Widget _buildTextFormField() {
    return Stack(
      children: [
        AppTextFormField(
          onTap: () {
            setState(() => _showCalendar = !_showCalendar);
            if (_showCalendar) {
              _startBlinking();
            } else {
              _stopBlinking();
            }
          },
          inputStyle: context.textTheme.bodyMedium?.copyWith(
            color: _showCalendar && _isBlinkingPrimary
                ? context.colorScheme.secondary
                : context.colorScheme.primary,
          ),
          textAlign: TextAlign.end,
          controller: _controller,
          readOnly: true,
          validator: widget.validator,
        ),
        Positioned(
          top: 14,
          left: 12,
          child: Text(
            widget.hintText ?? 'Select date',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withAlpha(120),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerContainer() {
    return AnimatedSwitcher(
      duration: 120.milliseconds,
      child: _showCalendar ? _buildCalendar() : const SizedBox.shrink(),
    );
  }

  Widget _buildCalendar() {
    return SizedBox(
      key: const ValueKey('calendar'),
      height: 240,
      child: TableCalendar(
        shouldFillViewport: true,
        enabledDayPredicate: (day) {
          if (widget.minimumDate != null) {
            // Check if day is before minimumDate
            if (day.isBefore(widget.minimumDate!) &&
                !day.isSameDay(widget.minimumDate!)) {
              return false;
            }
          }

          if (widget.maximumDate != null) {
            // Check if day is after maximumDate
            if (day.isAfter(widget.maximumDate!) &&
                !day.isSameDay(widget.maximumDate!)) {
              return false;
            }
          }

          // If we've passed all checks, the day is selectable
          return true;
        },
        headerVisible: false,
        focusedDay: _focusedDay,
        currentDay: DateTime.now(),
        firstDay: widget.minimumDate ?? DateTime.now().subtract(365.days),
        lastDay: widget.maximumDate ?? DateTime.now().add(365.days),
        selectedDayPredicate: (day) => _selectedDay?.isSameDay(day) ?? false,
        daysOfWeekHeight: 32,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        calendarBuilders: CalendarBuilders(
          selectedBuilder: _selectedDayBuilder,
          todayBuilder: _todayBuilder,
          dowBuilder: _buildDayOfWeek,
          defaultBuilder: _defaultDayBuilder,
        ),
        onDaySelected: _onDateSelected,
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = DateTime.now().isSameMonth(focusedDay)
                ? DateTime.now()
                : focusedDay;
          });
        },
      ),
    );
  }

  Widget _selectedDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: day.isSameDay(focusedDay) ? context.colorScheme.primary : null,
        border: Border.all(color: context.colorScheme.primary, width: 0.6),
        shape: BoxShape.circle,
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
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
}
