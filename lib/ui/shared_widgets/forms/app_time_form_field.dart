import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/shared_widgets/buttons/app_text_button.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTimeFormField extends StatefulWidget {
  const AppTimeFormField({
    super.key,
    this.controller,
    this.hintText,
    this.focusNode,
    this.initialTime,
    this.validator,
    this.minimumDate,
    this.maximumDate,
  });

  final TextEditingController? controller;
  final String? hintText;
  final FocusNode? focusNode;
  final TimeOfDay? initialTime;
  final String? Function(String?)? validator;
  final DateTime? minimumDate;
  final DateTime? maximumDate;

  @override
  State<AppTimeFormField> createState() => _AppTimeFormFieldState();
}

class _AppTimeFormFieldState extends State<AppTimeFormField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  TimeOfDay? _selectedTime;
  bool _showTimePicker = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    if (widget.initialTime != null) {
      _selectedTime = widget.initialTime;
      _updateControllerText();
    }

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_showTimePicker) {
        setState(() => _showTimePicker = true);
      }
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onTimeChanged(DateTime time) {
    setState(() {
      _selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
      _updateControllerText();
    });
  }

  void _onDone() {
    if (_selectedTime == null) {
      final now = TimeOfDay.now();
      setState(() {
        _selectedTime = now;
        _showTimePicker = false;
      });
      _updateControllerText();
    } else {
      setState(() => _showTimePicker = false);
    }
    _focusNode.unfocus();
  }

  void _updateControllerText() {
    if (_selectedTime != null) {
      // Create a DateTime with today's date and the selected time
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Format the time
      _controller.text = dateTime.toHHmma();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 150.milliseconds,
      alignment: Alignment.topCenter,
      child: Column(
        key: ValueKey(_showTimePicker),
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextFormField(),
          if (_showTimePicker) _buildTimePicker(),
        ],
      ),
    );
  }

  Widget _buildTextFormField() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (!_showTimePicker) {
              setState(() {
                _showTimePicker = true;
              });
            }
          },
          child: AppTextFormField(
            controller: _controller,
            hintText: widget.hintText,
            readOnly: true,
            focusNode: _focusNode,
            validator: widget.validator,
          ),
        ),
        if (_showTimePicker)
          Positioned(
            top: 10,
            right: 8,
            child: AppTextButton(text: 'Done', onTap: _onDone),
          ),
      ],
    );
  }

  Widget _buildTimePicker() {
    final now = DateTime.now();
    final initialDateTime = _selectedTime != null
        ? DateTime(
            now.year,
            now.month,
            now.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          )
        : now;

    return SizedBox(
      key: const ValueKey('timePicker'),
      height: 140,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: initialDateTime,
        onDateTimeChanged: _onTimeChanged,
        use24hFormat: false,
        minimumDate: widget.minimumDate,
        maximumDate: widget.maximumDate,
        selectionOverlayBuilder:
            (
              context, {
              required columnCount,
              required selectedIndex,
            }) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: <int>[1, 2].contains(selectedIndex)
                      ? Radius.zero
                      : const Radius.circular(UiConstants.borderRadiusValue),
                  topRight: <int>[0, 1].contains(selectedIndex)
                      ? Radius.zero
                      : const Radius.circular(UiConstants.borderRadiusValue),
                  bottomLeft: <int>[1, 2].contains(selectedIndex)
                      ? Radius.zero
                      : const Radius.circular(UiConstants.borderRadiusValue),
                  bottomRight: <int>[0, 1].contains(selectedIndex)
                      ? Radius.zero
                      : const Radius.circular(UiConstants.borderRadiusValue),
                ),
                color: context.colorScheme.onSurface.withAlpha(20),
              ),
            ),
      ),
    );
  }
}
