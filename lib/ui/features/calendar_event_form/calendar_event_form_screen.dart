import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/data/models/save_changes_dialog_options.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_form/widgets/calendar_event_form.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

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
  late String _title = widget.calendarEvent?.title ?? '';
  late DateTime _startDate =
      widget.calendarEvent?.startDate ?? widget.selectedDate!;
  late DateTime _endDate =
      widget.calendarEvent?.endDate ?? _startDate.add(10.minutes);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String? notes = widget.calendarEvent?.notes;
  late bool _allDay = widget.calendarEvent?.allDay ?? false;
  late EventColor _selectedColor =
      widget.calendarEvent?.eventColor ?? EventColor.black;
  late RepeatRule _repeatRule =
      widget.calendarEvent?.repeatRule ??
      const RepeatRule(frequency: RepeatFrequency.doNotRepeat);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarEventFormCubit>().initialize(widget.calendarEvent);
    });
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
        appBar: _buildAppBar(),
        body: CalendarEventForm(
          // Form validation
          formKey: _formKey,
          onSave: _onSave,

          // Basic event details
          title: _title,
          onTitleChanged: (value) => _title = value,
          selectedColor: _selectedColor,
          notes: notes ?? '',
          onNotesChanged: (value) => notes = value,

          // Date and time settings
          allDay: _allDay,
          startDate: _startDate,
          endDate: _endDate,
          onStartDateChanged: (value) => _startDate = value,
          onEndDateChanged: (value) => _endDate = value,
          onAllDayChanged: (value) => setState(() => _allDay = value),

          // Recurrence settings
          repeatRule: _repeatRule,
          onRepeatRuleChanged: (value) => setState(() => _repeatRule = value),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return MainAppBar.build(
      context,
      actions: [_buildColorSwitcherMenu(), const SizedBox(width: 8)],
    );
  }

  Widget _buildColorSwitcherMenu() {
    return PopupMenuButton<EventColor>(
      splashRadius: 0,
      color: context.colorScheme.surface,
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: UiConstants.borderRadius,
        side: BorderSide(
          color: context.colorScheme.outline,
          width: UiConstants.borderWidth,
        ),
      ),
      elevation: 0,
      offset: const Offset(0, 50),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        width: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: UiConstants.borderRadius,
            border: Border.all(
              color: context.colorScheme.outline,
              width: UiConstants.borderWidth,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 4),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _selectedColor.color,
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(Symbols.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
      ),
      onSelected: (value) => setState(() => _selectedColor = value),
      itemBuilder: (_) => EventColor.values
          .map(
            (e) => PopupMenuItem(
              value: e,
              height: 36,
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: e.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    e.label,
                    style: context.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (e == _selectedColor) const Icon(Symbols.check, size: 20),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _onSave() async {
    SaveChangesDialogOptions? saveOption;

    if (widget.calendarEvent?.isRecurring == true) {
      saveOption = await _showConfirmSaveDialog();
      if (saveOption == SaveChangesDialogOptions.cancel) return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      await context.read<CalendarEventFormCubit>().save(
        saveOption: saveOption,
        title: _title,
        notes: notes,
        startDate: _startDate,
        endDate: _endDate,
        allDay: _allDay,
        eventColor: _selectedColor,
        repeatRule: _repeatRule,
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
