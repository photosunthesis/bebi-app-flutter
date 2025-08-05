import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/day_of_week.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/ui/features/calendar_event_form/widgets/repeat_picker.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_date_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_time_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/switch/app_switch.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/extension/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CalendarEventForm extends StatefulWidget {
  const CalendarEventForm({
    required this.formKey,
    required this.titleController,
    required this.locationController,
    required this.dateController,
    required this.startTimeController,
    required this.endTimeController,
    required this.endRepeatDateController,
    required this.notesController,
    required this.allDay,
    required this.onAllDayChanged,
    required this.shareWithPartner,
    required this.onShareWithPartnerChanged,
    required this.selectedColor,
    required this.onSelectedColorChanged,
    required this.repeatFrequency,
    required this.daysOfWeekSelected,
    required this.onDaysOfWeekChanged,
    required this.onRepeatFrequencyChanged,
    this.selectedDate,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController locationController;
  final TextEditingController dateController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final TextEditingController endRepeatDateController;
  final TextEditingController notesController;
  final bool allDay;
  final ValueChanged<bool> onAllDayChanged;
  final bool shareWithPartner;
  final ValueChanged<bool> onShareWithPartnerChanged;
  final EventColors selectedColor;
  final ValueChanged<EventColors> onSelectedColorChanged;
  final RepeatFrequency repeatFrequency;
  final List<DayOfWeek> daysOfWeekSelected;
  final ValueChanged<List<DayOfWeek>> onDaysOfWeekChanged;
  final ValueChanged<RepeatFrequency> onRepeatFrequencyChanged;
  final DateTime? selectedDate;

  @override
  State<CalendarEventForm> createState() => _CalendarEventFormState();
}

class _CalendarEventFormState extends State<CalendarEventForm> {
  late DateTime? _repeatEndDateMinimum = widget.dateController.text.isEmpty
      ? null
      : widget.dateController.text.toEEEEMMMMdyyyyDate();

  @override
  void initState() {
    super.initState();
    widget.dateController.addListener(() {
      setState(() {
        _repeatEndDateMinimum = widget.dateController.text.isEmpty
            ? null
            : widget.dateController.text.toEEEEMMMMdyyyyDate();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(
              top: 16,
              left: UiConstants.padding,
              right: UiConstants.padding,
            ),
            sliver: SliverToBoxAdapter(child: _buildTitleAndLocationSection()),
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
          const SliverToBoxAdapter(
            child: SafeArea(child: SizedBox(height: UiConstants.padding)),
          ),
        ],
      ),
    );
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
                controller: widget.titleController,
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
                controller: widget.locationController,
                hintText: 'Location (optional)',
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.streetAddress,
                autofillHints: <String>[AutofillHints.fullStreetAddress],
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
        final isSelected = widget.selectedColor == eventColor;
        return GestureDetector(
          onTap: () => widget.onSelectedColorChanged(eventColor),
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
                minimumDate: _repeatEndDateMinimum,
                repeatFrequency: widget.repeatFrequency,
                onRepeatFrequencyChanged: widget.onRepeatFrequencyChanged,
                endDateController: widget.endRepeatDateController,
                daysOfWeekSelected: widget.daysOfWeekSelected,
                onDaysOfWeekChanged: widget.onDaysOfWeekChanged,
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
        AppSwitch(value: widget.allDay, onChanged: widget.onAllDayChanged),
      ],
    );
  }

  Widget _buildDateTimeFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDateFormField(
          controller: widget.dateController,
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
          duration: 120.milliseconds,
          alignment: Alignment.topCenter,
          child: !widget.allDay
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    AppTimeFormField(
                      controller: widget.startTimeController,
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
                      controller: widget.endTimeController,
                      hintText: 'End time',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'End time is required';
                        }

                        final startTime = widget.startTimeController.text
                            .toHHmmaTime();

                        if (startTime != null) {
                          final endTime = value.toHHmmaTime();
                          if (endTime == null ||
                              endTime.isBefore(startTime) ||
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
                controller: widget.notesController,
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
          value: widget.shareWithPartner,
          onChanged: widget.onShareWithPartnerChanged,
        ),
      ],
    );
  }
}
