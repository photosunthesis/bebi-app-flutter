import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/day_of_week.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_form/widgets/calendar_event_form.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CalendarEventFormScreen extends StatefulWidget {
  const CalendarEventFormScreen({
    this.calendarEvent,
    this.selectedDate,
    super.key,
  });

  final CalendarEvent? calendarEvent;
  final DateTime? selectedDate;

  @override
  State<CalendarEventFormScreen> createState() =>
      _CalendarEventFormScreenState();
}

class _CalendarEventFormScreenState extends State<CalendarEventFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final _cubit = context.read<CalendarEventFormCubit>();
  late final _titleController = TextEditingController(
    text: widget.calendarEvent?.title,
  );
  late final _locationController = TextEditingController(
    text: widget.calendarEvent?.location,
  );
  late final _dateController = TextEditingController(
    text: (widget.calendarEvent?.date ?? widget.selectedDate)!
        .toEEEEMMMMdyyyy(),
  );
  late final _startTimeController = TextEditingController(
    text: widget.calendarEvent?.startTime.toHHmma(),
  );
  late final _endTimeController = TextEditingController(
    text: widget.calendarEvent?.endTime?.toHHmma(),
  );
  late final _endRepeatDateController = TextEditingController(
    text: widget.calendarEvent?.repeatRule.endDate?.toEEEEMMMMdyyyy(),
  );
  late final _notesController = TextEditingController(
    text: widget.calendarEvent?.notes,
  );
  late List<DayOfWeek> _daysOfWeekSelected =
      widget.calendarEvent?.repeatRule.daysOfWeek != null
      ? widget.calendarEvent!.repeatRule.daysOfWeek!
            .map(DayOfWeek.fromIndex)
            .toList()
      : const <DayOfWeek>[];
  late bool _allDay = widget.calendarEvent?.allDay ?? false;
  late bool _shareWithPartner = (widget.calendarEvent?.users.length ?? 2) > 1;
  late EventColors _selectedColor =
      widget.calendarEvent?.eventColor ?? EventColors.black;
  late RepeatFrequency _repeatFrequency =
      widget.calendarEvent?.repeatRule.frequency ?? RepeatFrequency.doNotRepeat;

  @override
  void initState() {
    super.initState();
    _cubit.initialize(widget.calendarEvent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _endRepeatDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalendarEventFormCubit, CalendarEventFormState>(
      listener: (context, state) {
        if (state.error != null) context.showSnackbar(state.error!);
        if (state.success) {
          try {
            // Return true if we're creating a new event,
            if (widget.calendarEvent == null) return context.pop(true);
            // Otherwise return the updated event
            context.pop(state.calendarEvent);
          } catch (_) {
            // GoRouter thinks there's nothing left to pop, even though this
            // route was definitely pushed somewhere in the code. The pop
            // actually works and returns a value just fine, but throws
            // an error anyway. So we're just catching and ignoring it...
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: CalendarEventForm(
          formKey: _formKey,
          titleController: _titleController,
          locationController: _locationController,
          dateController: _dateController,
          startTimeController: _startTimeController,
          endTimeController: _endTimeController,
          endRepeatDateController: _endRepeatDateController,
          notesController: _notesController,
          allDay: _allDay,
          onAllDayChanged: (value) => setState(() => _allDay = value),
          shareWithPartner: _shareWithPartner,
          onShareWithPartnerChanged: (value) =>
              setState(() => _shareWithPartner = value),
          selectedColor: _selectedColor,
          onSelectedColorChanged: (value) =>
              setState(() => _selectedColor = value),
          repeatFrequency: _repeatFrequency,
          onRepeatFrequencyChanged: (value) =>
              setState(() => _repeatFrequency = value),
          selectedDate: widget.selectedDate,
          daysOfWeekSelected: _daysOfWeekSelected,
          onDaysOfWeekChanged: (value) =>
              setState(() => _daysOfWeekSelected = value),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return MainAppBar.build(
      context,
      darkStatusBarIcons: false,
      leading: IconButton(
        icon: const Icon(Symbols.close),
        onPressed: context.pop,
      ),
      actions: [
        BlocSelector<CalendarEventFormCubit, CalendarEventFormState, bool>(
          selector: (state) => state.loading,
          builder: (context, loading) {
            return TextButton(
              style: TextButton.styleFrom(
                textStyle: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: loading ? null : _onSave,
              child: Text(loading ? 'Saving' : 'Save'),
            );
          },
        ),
      ],
    );
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final date = _dateController.text.toEEEEMMMMdyyyyDate()!;
      final startTimeParsed = _startTimeController.text.toHHmmaTime();
      final endTimeParsed = _endTimeController.text.toHHmmaTime();
      final endRepeatDate = _endRepeatDateController.text.toEEEEMMMMdyyyyDate();

      final repeat = RepeatRule(
        frequency: _repeatFrequency,
        endDate: endRepeatDate,
        daysOfWeek: _repeatFrequency == RepeatFrequency.weekly
            ? _daysOfWeekSelected.map((e) => e.index).toList()
            : null,
      );

      _cubit.save(
        title: _titleController.text,
        location: _locationController.text,
        notes: _notesController.text,
        date: date,
        startTime: DateTime(
          date.year,
          date.month,
          date.day,
          startTimeParsed?.hour ?? 0,
          startTimeParsed?.minute ?? 0,
        ),
        endTime: DateTime(
          date.year,
          date.month,
          date.day,
          endTimeParsed?.hour ?? 0,
          endTimeParsed?.minute ?? 0,
        ),
        allDay: _allDay,
        eventColor: _selectedColor,
        shareWithPartner: _shareWithPartner,
        repeatRule: repeat,
      );
    }
  }
}
