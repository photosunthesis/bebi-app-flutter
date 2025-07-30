import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_form/widgets/repeat_picker.dart';
import 'package:bebi_app/ui/shared_widgets/buttons/app_text_button.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_date_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_time_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/ui/shared_widgets/switch/app_switch.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CalendarEventFormBottomSheet extends StatefulWidget {
  const CalendarEventFormBottomSheet({
    super.key,
    this.calendarEventId,
    this.selectedDate,
  });

  final String? calendarEventId;
  final DateTime? selectedDate;

  @override
  State<CalendarEventFormBottomSheet> createState() =>
      _CalendarEventFormBottomSheetState();
}

class _CalendarEventFormBottomSheetState
    extends State<CalendarEventFormBottomSheet> {
  late final _cubit = context.read<CalendarEventFormCubit>();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _endRepeatDateController = TextEditingController();
  final _notesController = TextEditingController();

  bool _allDay = false;
  bool _shareWithPartner = true;
  EventColors _selectedColor = EventColors.black;
  RepeatFrequency _repeatFrequency = RepeatFrequency.doNotRepeat;

  @override
  void initState() {
    super.initState();
    _cubit.initialize(widget.calendarEventId);
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
            context.pop(true);
          } catch (_) {
            // GoRouter thinks there's nothing left to pop, even though this
            // route was definitely pushed somewhere in the code. The pop
            // actually works and returns the boolean just fine, but throws
            // an error anyway. So we're just catching and ignoring it...
            // because sometimes that's just how routing rolls :D
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: UiConstants.padding,
                  right: UiConstants.padding,
                ),
                sliver: SliverToBoxAdapter(
                  child: _buildTitleAndLocationSection(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(
                  top: 18,
                  left: UiConstants.padding,
                  right: UiConstants.padding,
                ),
                sliver: SliverToBoxAdapter(child: _buildDateTimeSection()),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: UiConstants.padding,
                  right: UiConstants.padding,
                ),
                sliver: SliverToBoxAdapter(child: _buildOtherDetailsSection()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Symbols.close),
        onPressed: context.pop,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: AppTextButton.primary(text: 'Save', onTap: _onSave),
        ),
        const SizedBox(width: UiConstants.padding),
      ],
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: context.colorScheme.onSecondary,
          height: UiConstants.borderWidth,
        ),
      ),
    );
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final date = DateFormat(
        'EEEE MMMM d, yyyy',
      ).parseStrict(_dateController.text);

      final startTimeParsed = DateFormat(
        'h:mm a',
      ).tryParseStrict(_startTimeController.text);

      final endTimeParsed = DateFormat(
        'h:mm a',
      ).tryParseStrict(_endTimeController.text);

      final endRepeatDate = DateFormat(
        'EEEE MMMM d, yyyy',
      ).tryParseStrict(_endRepeatDateController.text);

      final repeat = RepeatRule(
        frequency: _repeatFrequency,
        endDate: endRepeatDate,
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

  Widget _buildTitleAndLocationSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 8),
          child: Icon(
            Symbols.subheader,
            color: context.colorScheme.onSurface.withAlpha(180),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextFormField(
                controller: _titleController,
                hintText: 'Title',
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 2),
              AppTextFormField(
                controller: _locationController,
                hintText: 'Location (optional)',
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.streetAddress,
                autofillHints: [AutofillHints.fullStreetAddress],
              ),
              const SizedBox(height: 4),
              _buildColorSelector(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: EventColors.values.map((eventColor) {
        final isSelected = _selectedColor == eventColor;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = eventColor),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: eventColor.color,
              shape: BoxShape.circle,
            ),
            child: isSelected
                ? const Icon(Symbols.check, color: Colors.white, size: 26)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 8),
          child: Icon(
            Symbols.calendar_today,
            color: context.colorScheme.onSurface.withAlpha(180),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAllDayToggle(),
              const SizedBox(height: 6),
              _buildDateTimeFields(),
              const SizedBox(height: 4),
              RepeatPicker(
                repeatFrequency: _repeatFrequency,
                onRepeatFrequencyChanged: (value) =>
                    setState(() => _repeatFrequency = value),
                endDateController: _endRepeatDateController,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllDayToggle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('All-day'),
        const Spacer(),
        AppSwitch(
          value: _allDay,
          onChanged: (value) => setState(() => _allDay = value),
        ),
      ],
    );
  }

  Widget _buildDateTimeFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDateFormField(
          controller: _dateController,
          hintText: 'Date',
          focusedDay: widget.selectedDate,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Date is required';
            }
            return null;
          },
        ),
        AnimatedSize(
          duration: 150.milliseconds,
          alignment: Alignment.topCenter,
          child: !_allDay
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    AppTimeFormField(
                      controller: _startTimeController,
                      hintText: 'Start time',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Start time is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    AppTimeFormField(
                      controller: _endTimeController,
                      hintText: 'End time',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'End time is required';
                        }

                        final startTime = DateFormat(
                          'h:mm a',
                        ).tryParse(_startTimeController.text);

                        if (startTime != null) {
                          final endTime = DateFormat('h:mm a').parse(value);
                          if (endTime.isBefore(startTime) ||
                              endTime.isAtSameMomentAs(startTime)) {
                            return 'End time must be after start time';
                          }
                        }

                        return null;
                      },
                    ),
                  ],
                )
              : Container(),
        ),
      ],
    );
  }

  Widget _buildOtherDetailsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 8),
          child: Icon(
            Symbols.notes,
            color: context.colorScheme.onSurface.withAlpha(180),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildShareWithPartnerToggle(),
              const SizedBox(height: 6),
              AppTextFormField(
                controller: _notesController,
                hintText: 'Notes (optional)',
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareWithPartnerToggle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Share with partner'),
        const Spacer(),
        AppSwitch(
          value: _shareWithPartner,
          onChanged: (value) => setState(() => _shareWithPartner = value),
        ),
      ],
    );
  }
}
