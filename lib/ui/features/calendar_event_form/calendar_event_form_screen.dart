import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/day_of_week.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/data/models/save_changes_dialog_options.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_form/widgets/calendar_event_form.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late final _dateController = TextEditingController(
    text: (widget.calendarEvent?.date ?? widget.selectedDate)!
        .toEEEEMMMMdyyyy(),
  );
  late final _startTimeController = TextEditingController(
    text:
        widget.calendarEvent?.startTime.toHHmma() ??
        widget.selectedDate?.toHHmma(),
  );
  late final _endTimeController = TextEditingController(
    text:
        widget.calendarEvent?.endTime?.toHHmma() ??
        widget.selectedDate?.add(const Duration(hours: 1)).toHHmma(),
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
            .map((index) => DayOfWeek.values[index])
            .toList()
      : widget.selectedDate != null
      ? [DayOfWeek.values[widget.selectedDate!.toLocal().weekday - 1]]
      : const [];
  late bool _allDay = widget.calendarEvent?.allDay ?? false;
  late bool _shareWithPartner = (widget.calendarEvent?.users.length ?? 2) > 1;
  late EventColor _selectedColor =
      widget.calendarEvent?.eventColor ?? EventColor.black;
  late RepeatFrequency _repeatFrequency =
      widget.calendarEvent?.repeatRule.frequency ?? RepeatFrequency.doNotRepeat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.initialize(widget.calendarEvent);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
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
      listener: (context, state) => switch (state) {
        CalendarEventFormErrorState(:final error) => context.showSnackbar(
          error,
          type: SnackbarType.error,
        ),
        CalendarEventFormSuccessState() => context.goNamed(
          AppRoutes.calendar,
          queryParameters: {'loadEventsFromServer': 'true'},
        ),
        _ => null,
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: CalendarEventForm(
          formKey: _formKey,
          titleController: _titleController,
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
          selector: (state) => state is CalendarEventFormLoadingState,
          builder: (context, loading) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 10, 12),
              child: OutlinedButton(
                onPressed: loading ? null : _onSave,
                child: Text(
                  (loading
                          ? context.l10n.savingButton
                          : context.l10n.saveButton)
                      .toUpperCase(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _onSave() async {
    SaveChangesDialogOptions? saveOption;

    if (widget.calendarEvent?.isRecurring == true) {
      saveOption = await _showConfirmSaveDialog();
      if (saveOption == SaveChangesDialogOptions.cancel) return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final date = _dateController.text.toEEEMMMdyyyyDate()!;
      final startTimeParsed = _startTimeController.text.toHHmmaTime();
      final endTimeParsed = _endTimeController.text.toHHmmaTime();
      final endRepeatDate = _endRepeatDateController.text.toEEEMMMdyyyyDate();

      final repeat = RepeatRule(
        frequency: _repeatFrequency,
        endDate: endRepeatDate,
        daysOfWeek: _repeatFrequency == RepeatFrequency.weekly
            ? _daysOfWeekSelected.map((e) => e.index).toList()
            : null,
      );

      await _cubit.save(
        saveOption: saveOption,
        title: _titleController.text,
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

  Future<SaveChangesDialogOptions> _showConfirmSaveDialog() async {
    final result = await OptionsBottomDialog.show(
      context,
      title: context.l10n.saveChangesToEventTitle,
      description: context.l10n.saveChangesToEventMessage,
      options: [
        Option(
          text: context.l10n.saveOnlyThisEvent,
          value: SaveChangesDialogOptions.onlyThisEvent,
          style: OptionStyle.primary,
        ),
        Option(
          text: context.l10n.saveAllFutureEvents,
          value: SaveChangesDialogOptions.allFutureEvents,
          style: OptionStyle.primary,
        ),
        Option(
          text: context.l10n.cancelButton,
          value: SaveChangesDialogOptions.cancel,
        ),
      ],
    );

    return result ?? SaveChangesDialogOptions.cancel;
  }
}
