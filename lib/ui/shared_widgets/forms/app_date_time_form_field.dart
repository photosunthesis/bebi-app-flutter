import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/shared_widgets/buttons/app_text_button.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

class AppDateTimeFormField extends StatefulWidget {
  const AppDateTimeFormField({
    super.key,
    this.controller,
    this.hintText,
    this.focusNode,
    this.minSelectableDate,
    this.maxSelectableDate,
    this.focusedDay,
    this.hasTime = true,
    this.validator,
  });

  final TextEditingController? controller;
  final String? hintText;
  final FocusNode? focusNode;
  final DateTime? minSelectableDate;
  final DateTime? maxSelectableDate;
  final DateTime? focusedDay;
  final bool hasTime;
  final String? Function(String?)? validator;

  @override
  State<AppDateTimeFormField> createState() => _AppDateTimeFormFieldState();
}

class _AppDateTimeFormFieldState extends State<AppDateTimeFormField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late DateTime _focusedDay;
  late DateTime _selectedTime;
  DateTime? _selectedDay;
  bool _showCalendar = false;
  bool _showTimePicker = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusedDay = widget.focusedDay ?? DateTime.now();

    if (widget.focusedDay != null) {
      _selectedDay = widget.focusedDay;
      _selectedTime = widget.focusedDay!;
      _updateControllerText(showTime: widget.hasTime);
    } else {
      _selectedTime = DateTime.now();
    }

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_showCalendar && !_showTimePicker) {
        setState(() => _showCalendar = true);
      }
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppDateTimeFormField oldWidget) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllerText(
        showTime: oldWidget.hasTime != widget.hasTime && widget.hasTime,
      );
    });

    super.didUpdateWidget(oldWidget);
  }

  void _onDateSelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _showCalendar = false;

      if (widget.hasTime) {
        _showTimePicker = true;
        _selectedTime = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          DateTime.now().hour,
          DateTime.now().minute,
        );
      } else {
        _selectedTime = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
          0,
          0,
        );
      }

      _updateControllerText(showTime: widget.hasTime);
    });

    if (!widget.hasTime) _focusNode.unfocus();
  }

  void _onTimeChanged(DateTime time) {
    setState(() {
      _selectedTime = time;
      _updateControllerText(showTime: true);
    });
  }

  void _onDone() {
    setState(() {
      _showTimePicker = false;
      _showCalendar = false;
    });
    _focusNode.unfocus();
  }

  void _updateControllerText({required bool showTime}) {
    if (_selectedDay != null) {
      final dateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (showTime) {
        _controller.text = dateTime.toEEEEMMMMdyyyyhhmma();
      } else {
        _controller.text = dateTime.toEEEEMMMMdyyyy();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 150.milliseconds,
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
        GestureDetector(
          onTap: () {
            if (!_showCalendar && !_showTimePicker) {
              setState(() {
                _showCalendar = true;
              });
            }
          },
          child: AppTextFormField(
            controller: _controller,
            hintText: widget.hintText,
            readOnly: true,
            focusNode: _focusNode,
            validator: widget.validator,
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'.*'))],
          ),
        ),
        if (_showCalendar || _showTimePicker)
          Positioned(
            top: 10,
            right: 8,
            child: AppTextButton(text: 'Done', onTap: _onDone),
          ),
      ],
    );
  }

  Widget _buildPickerContainer() {
    return AnimatedSwitcher(
      duration: 150.milliseconds,
      child: _showCalendar
          ? _buildCalendar()
          : _showTimePicker
          ? _buildTimePicker()
          : const SizedBox.shrink(),
    );
  }

  Widget _buildCalendar() {
    return SizedBox(
      key: const ValueKey('calendar'),
      child: TableCalendar(
        enabledDayPredicate: (day) {
          if (widget.minSelectableDate != null &&
              widget.maxSelectableDate != null) {
            return day.isAfter(widget.minSelectableDate!) &&
                day.isBefore(widget.maxSelectableDate!);
          }

          if (widget.minSelectableDate != null &&
              day.isBefore(widget.minSelectableDate!)) {
            return false;
          }

          if (widget.maxSelectableDate != null &&
              day.isAfter(widget.maxSelectableDate!)) {
            return false;
          }

          return true;
        },
        headerVisible: false,
        focusedDay: _focusedDay,
        currentDay: DateTime.now(),
        // TODO Improve how first day and last day is determined
        firstDay: widget.minSelectableDate ?? DateTime.now().subtract(365.days),
        lastDay: widget.maxSelectableDate ?? DateTime.now().add(365.days),
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

  Widget _buildTimePicker() {
    return SizedBox(
      key: const ValueKey('timePicker'),
      height: 140,
      child: CupertinoTheme(
        data: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: _selectedTime,
          onDateTimeChanged: _onTimeChanged,
          showTimeSeparator: true,
          itemExtent: 32,
          selectionOverlayBuilder:
              (context, {required columnCount, required selectedIndex}) =>
                  Container(),
        ),
      ),
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
      margin: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: day.isSameDay(focusedDay) ? context.colorScheme.primary : null,
        borderRadius: UiConstants.borderRadius,
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
