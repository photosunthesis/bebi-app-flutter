import 'package:bebi_app/data/models/day_of_week.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_date_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_multiple_choice_dropdown.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_dropdown_picker.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/cupertino.dart';

class RepeatPicker extends StatefulWidget {
  const RepeatPicker({
    required this.endDateController,
    required this.daysOfWeekSelected,
    required this.onRepeatFrequencyChanged,
    required this.onDaysOfWeekChanged,
    this.repeatFrequency = RepeatFrequency.doNotRepeat,
    this.minimumDate,
    super.key,
  });

  final TextEditingController endDateController;
  final RepeatFrequency repeatFrequency;
  final List<DayOfWeek> daysOfWeekSelected;
  final ValueChanged<RepeatFrequency> onRepeatFrequencyChanged;
  final ValueChanged<List<DayOfWeek>> onDaysOfWeekChanged;
  final DateTime? minimumDate;

  @override
  State<RepeatPicker> createState() => _RepeatPickerState();
}

class _RepeatPickerState extends State<RepeatPicker> {
  late final _daysOfWeekController = TextEditingController(
    text: widget.daysOfWeekSelected
        .map((e) => e.toTitle().substring(0, 3))
        .join(', '),
  );

  bool get _showEndDate =>
      widget.repeatFrequency != RepeatFrequency.doNotRepeat;

  late bool _showDaysOfWeekPicker =
      widget.repeatFrequency == RepeatFrequency.weekly;

  // TODO Implement custom repeats
  final frequencies = RepeatFrequency.values
      .where((f) => f != RepeatFrequency.custom)
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.daysOfWeekSelected.isEmpty && widget.minimumDate != null) {
        final dayOfWeek = DayOfWeek.values[widget.minimumDate!.weekday - 1];
        widget.onDaysOfWeekChanged([dayOfWeek]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 120.milliseconds,
      curve: Curves.easeOutCirc,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextDropdownPicker(
            hintText: 'Repeat',
            height: 100,
            selectedIndex: frequencies.indexOf(widget.repeatFrequency),
            items: frequencies,
            labelBuilder: (item) => item.label,
            onChanged: (freq) {
              widget.onRepeatFrequencyChanged(freq);
              setState(
                () => _showDaysOfWeekPicker = freq == RepeatFrequency.weekly,
              );
            },
          ),
          if (_showDaysOfWeekPicker)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AppMultipleChoiceDropdown<DayOfWeek>(
                controller: _daysOfWeekController,
                hintText: 'Days of week',
                items: DayOfWeek.values,
                selectedItems: widget.daysOfWeekSelected,
                onChanged: widget.onDaysOfWeekChanged,
                itemLabelBuilder: (item) => item.toTitle(),
              ),
            ),
          if (_showEndDate)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AppDateFormField(
                controller: widget.endDateController,
                hintText: 'End repeat date',
                minimumDate: widget.minimumDate,
              ),
            ),
          // TODO Implement widgets to handle custom repeats
        ],
      ),
    );
  }
}
