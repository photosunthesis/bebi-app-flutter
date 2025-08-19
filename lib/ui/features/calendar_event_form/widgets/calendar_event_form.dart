import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/ui/features/calendar_event_form/calendar_event_form_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_form/widgets/repeat_picker.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_date_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_time_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/switch/app_switch.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/color_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class CalendarEventForm extends StatefulWidget {
  const CalendarEventForm({
    required this.formKey,
    required this.titleController,
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
    required this.onRepeatFrequencyChanged,
    this.selectedDate,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController dateController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final TextEditingController endRepeatDateController;
  final TextEditingController notesController;
  final bool allDay;
  final ValueChanged<bool> onAllDayChanged;
  final bool shareWithPartner;
  final ValueChanged<bool> onShareWithPartnerChanged;
  final EventColor selectedColor;
  final ValueChanged<EventColor> onSelectedColorChanged;
  final RepeatFrequency repeatFrequency;
  final ValueChanged<RepeatFrequency> onRepeatFrequencyChanged;
  final DateTime? selectedDate;

  @override
  State<CalendarEventForm> createState() => _CalendarEventFormState();
}

class _CalendarEventFormState extends State<CalendarEventForm> {
  late DateTime? _repeatEndDateMinimum = widget.dateController.text.isEmpty
      ? null
      : widget.dateController.text.toEEEMMMdyyyyDate();

  @override
  void initState() {
    super.initState();
    widget.dateController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _repeatEndDateMinimum = widget.dateController.text.isEmpty
              ? null
              : widget.dateController.text.toEEEMMMdyyyyDate();
        });
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
            padding: const EdgeInsets.only(top: 16, left: 10, right: 10),
            sliver: SliverToBoxAdapter(child: _buildAndColorTitleSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: UiConstants.padding,
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

  Widget _buildAndColorTitleSection() {
    return Column(
      children: [
        AppTextFormField(
          autofocus: true,
          inputBorder: InputBorder.none,
          controller: widget.titleController,
          hintText: context.l10n.newEventHint,
          textInputAction: TextInputAction.done,
          inputStyle: context.primaryTextTheme.headlineSmall?.copyWith(
            color: widget.selectedColor.color.darken(0.2),
          ),
          maxLines: 2,
          minLines: 1,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n.titleRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        _buildColorSelector(),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: EventColor.values.map((eventColor) {
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
      ),
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
            color: widget.selectedColor.color.darken(),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllDayToggle() {
    return Row(
      children: [
        Text(context.l10n.allDayText, style: context.textTheme.bodyMedium),
        const Spacer(),
        AppSwitch(
          value: widget.allDay,
          onChanged: widget.onAllDayChanged,
          activeColor: widget.selectedColor.color,
        ),
      ],
    );
  }

  Widget _buildDateTimeFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDateFormField(
          controller: widget.dateController,
          hintText: context.l10n.dateHint,
          focusedDay: widget.selectedDate,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return context.l10n.dateRequired;
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
                      hintText: context.l10n.startTimeHint,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n.startTimeRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    AppTimeFormField(
                      controller: widget.endTimeController,
                      hintText: context.l10n.endTimeHint,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n.endTimeRequired;
                        }

                        final startTime = widget.startTimeController.text
                            .toHHmmaTime();

                        if (startTime != null) {
                          final endTime = value.toHHmmaTime();
                          if (endTime == null ||
                              endTime.isBefore(startTime) ||
                              endTime.isAtSameMomentAs(startTime)) {
                            return context.l10n.endTimeAfterStartTime;
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
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 14, top: 8),
              child: Icon(
                Symbols.notes,
                color: widget.selectedColor.color.darken(),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildShareWithPartnerToggle(),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: widget.notesController,
                    hintText: context.l10n.notesHint,
                    minLines: 3,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareWithPartnerToggle() {
    return BlocSelector<CalendarEventFormCubit, CalendarEventFormState, bool>(
      selector: (state) => state is CalendarEventFormLoadedState
          ? state.eventWasCreatedByCurrentUser
          : false,
      builder: (context, eventWasCreatedByCurrentUser) {
        return Row(
          children: [
            Text(
              eventWasCreatedByCurrentUser
                  ? context.l10n.shareWithPartner
                  : context.l10n.eventSharedWithYou,
            ),
            const Spacer(),
            if (eventWasCreatedByCurrentUser)
              AppSwitch(
                enabled: eventWasCreatedByCurrentUser,
                value: widget.shareWithPartner,
                onChanged: widget.onShareWithPartnerChanged,
                activeColor: widget.selectedColor.color,
              )
            else
              const SizedBox(height: 39),
          ],
        );
      },
    );
  }
}
