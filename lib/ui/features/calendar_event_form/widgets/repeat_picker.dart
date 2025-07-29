import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_date_time_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_dropdown_picker.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/cupertino.dart';

class RepeatPicker extends StatefulWidget {
  const RepeatPicker({
    required this.endDateController,
    this.repeatFrequency,
    this.onRepeatFrequencyChanged,
    super.key,
  });

  final RepeatFrequency? repeatFrequency;
  final ValueChanged<RepeatFrequency?>? onRepeatFrequencyChanged;
  final TextEditingController endDateController;

  @override
  State<RepeatPicker> createState() => _RepeatPickerState();
}

class _RepeatPickerState extends State<RepeatPicker> {
  bool get _shouldShowEndDate =>
      widget.repeatFrequency != null &&
      widget.repeatFrequency != RepeatFrequency.doNotRepeat;

  // TODO Implement custom repeats
  final frequencies = RepeatFrequency.values
      .where((f) => f != RepeatFrequency.custom)
      .toList();

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 150.milliseconds,
      curve: Curves.easeOutCirc,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextDropdownPicker(
            hintText: 'Repeat',
            height: 100,
            selectedIndex: widget.repeatFrequency != null
                ? frequencies.indexOf(widget.repeatFrequency!)
                : frequencies.length - 1,
            items: frequencies,
            labelBuilder: (item) => item.label,
            onChanged: (value) => widget.onRepeatFrequencyChanged?.call(value),
          ),
          AnimatedSwitcher(
            duration: 150.milliseconds,
            child: _shouldShowEndDate
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: AppDateTimeFormField(
                      controller: widget.endDateController,
                      hintText: 'End repeat date',
                      hasTime: false,
                    ),
                  )
                : null,
          ),
          // TODO Implement widgets to handle custom repeats
        ],
      ),
    );
  }
}
