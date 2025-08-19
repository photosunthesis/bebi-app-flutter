import 'dart:async';

import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTimeFormField extends StatefulWidget {
  const AppTimeFormField({
    super.key,
    this.controller,
    this.hintText,
    this.initialTime,
    this.validator,
    this.minimumDate,
    this.maximumDate,
  });

  final TextEditingController? controller;
  final String? hintText;
  final TimeOfDay? initialTime;
  final String? Function(String?)? validator;
  final DateTime? minimumDate;
  final DateTime? maximumDate;

  @override
  State<AppTimeFormField> createState() => _AppTimeFormFieldState();
}

class _AppTimeFormFieldState extends State<AppTimeFormField> {
  late final _controller = widget.controller ?? TextEditingController();
  TimeOfDay? _selectedTime;
  bool _showTimePicker = false;
  Timer? _blinkTimer;
  Timer? _closeTimer;
  bool _isBlinkingSecondary = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTime != null) {
      _selectedTime = widget.initialTime;
      _updateControllerText();
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _closeTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onTimeChanged(DateTime time) {
    _closeTimer?.cancel();
    setState(() {
      _selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
      _updateControllerText();
    });
    _closeTimer = Timer(2.seconds, _onDone);
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
    _stopBlinking();
  }

  void _startBlinking() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(400.milliseconds, (timer) {
      setState(() {
        _isBlinkingSecondary = !_isBlinkingSecondary;
      });
    });
  }

  void _stopBlinking() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    setState(() {
      _isBlinkingSecondary = false;
    });
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
      duration: 120.milliseconds,
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
        AppTextFormField(
          onTap: () {
            if (!_showTimePicker) {
              setState(() => _showTimePicker = true);
              _startBlinking();
            } else {
              setState(() => _showTimePicker = false);
              _onDone();
            }
          },
          inputStyle: context.textTheme.bodyMedium?.copyWith(
            color: _showTimePicker && _isBlinkingSecondary
                ? context.colorScheme.secondary
                : context.colorScheme.primary,
          ),
          textAlign: TextAlign.end,
          controller: _controller,
          readOnly: true,
          validator: widget.validator,
        ),
        Positioned(
          top: 14,
          left: 12,
          child: Text(
            widget.hintText ?? context.l10n.selectTime,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface.withAlpha(120),
            ),
          ),
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
        minimumDate: widget.minimumDate,
        maximumDate: widget.maximumDate,
        selectionOverlayBuilder:
            (context, {required columnCount, required selectedIndex}) =>
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    color: context.colorScheme.onSurface.withAlpha(20),
                  ),
                ),
      ),
    );
  }
}
