import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_date_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_dropdown_picker.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:flutter/cupertino.dart';

class RepeatPicker extends StatefulWidget {
  const RepeatPicker({
    required this.endDateController,
    required this.onRepeatFrequencyChanged,
    this.repeatFrequency = RepeatFrequency.doNotRepeat,
    this.minimumDate,
    super.key,
  });

  final TextEditingController endDateController;
  final RepeatFrequency repeatFrequency;
  final ValueChanged<RepeatFrequency> onRepeatFrequencyChanged;
  final DateTime? minimumDate;

  @override
  State<RepeatPicker> createState() => _RepeatPickerState();
}

class _RepeatPickerState extends State<RepeatPicker> {
  bool get _showEndDate =>
      widget.repeatFrequency != RepeatFrequency.doNotRepeat;

  // TODO Implement custom repeats
  final frequencies = RepeatFrequency.values
      .where((f) => f != RepeatFrequency.custom)
      .toList();

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
            hintText: context.l10n.repeatHint,
            height: 100,
            selectedIndex: frequencies.indexOf(widget.repeatFrequency),
            items: frequencies,
            labelBuilder: (item) => item.label,
            onChanged: widget.onRepeatFrequencyChanged,
          ),
          if (_showEndDate)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AppDateFormField(
                controller: widget.endDateController,
                hintText: context.l10n.endRepeatDateHint,
                minimumDate: widget.minimumDate,
              ),
            ),
          // TODO Implement widgets to handle custom repeats
        ],
      ),
    );
  }
}
