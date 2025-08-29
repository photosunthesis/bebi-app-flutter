import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/ui/shared_widgets/pickers/app_date_time_picker.dart';
import 'package:bebi_app/ui/shared_widgets/switch/app_switch.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class DateFieldsBottomDialog<T> extends StatefulWidget {
  const DateFieldsBottomDialog._({
    super.key,
    required this.startDate,
    required this.onStartDateChanged,
    required this.endDate,
    required this.onEndDateChanged,
    required this.repeatRule,
    required this.onRepeatRuleChanged,
    required this.allDay,
    required this.onAllDayChanged,
  });

  final DateTime startDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final DateTime endDate;
  final ValueChanged<DateTime> onEndDateChanged;
  final RepeatRule repeatRule;
  final ValueChanged<RepeatRule> onRepeatRuleChanged;
  final bool allDay;
  final ValueChanged<bool> onAllDayChanged;

  static Future<T?> show<T>(
    BuildContext context, {
    required DateTime startDate,
    required ValueChanged<DateTime> onStartDateChanged,
    required DateTime endDate,
    required ValueChanged<DateTime> onEndDateChanged,
    required RepeatRule repeatRule,
    required ValueChanged<RepeatRule> onRepeatRuleChanged,
    required bool allDay,
    required ValueChanged<bool> onAllDayChanged,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: false,
      barrierColor: context.colorScheme.primary.withAlpha(80),
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DateFieldsBottomDialog._(
        startDate: startDate,
        onStartDateChanged: onStartDateChanged,
        endDate: endDate,
        onEndDateChanged: onEndDateChanged,
        repeatRule: repeatRule,
        onRepeatRuleChanged: onRepeatRuleChanged,
        allDay: allDay,
        onAllDayChanged: onAllDayChanged,
      ),
    );
  }

  @override
  State<DateFieldsBottomDialog<T>> createState() =>
      _DateFieldsBottomDialogState<T>();
}

class _DateFieldsBottomDialogState<T> extends State<DateFieldsBottomDialog<T>> {
  late RepeatFrequency _repeatFrequency = widget.repeatRule.frequency;
  late bool _allDay = widget.allDay;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 120.milliseconds,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: context.colorScheme.outline.withAlpha(80),
                    borderRadius: UiConstants.borderRadius,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UiConstants.padding,
              ),
              child: Text(
                'Set event date',
                style: context.primaryTextTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 18),
            _buildFields(context),
            const SizedBox(height: 16),
            _buildDoneButton(context),
            const SafeArea(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFields(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      decoration: BoxDecoration(
        borderRadius: UiConstants.borderRadius,
        border: Border.all(
          color: context.colorScheme.outline,
          width: UiConstants.borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAllDaySection(),
          _buildDivider(),
          AppDateTimePicker(
            label: _allDay ? context.l10n.dateHint : context.l10n.startDateHint,
            value: widget.startDate,
            onChanged: widget.onStartDateChanged,
            allDay: _allDay,
          ),
          _buildDivider(),
          if (!_allDay) ...[
            AppDateTimePicker(
              label: context.l10n.endDateHint,
              value: widget.endDate,
              onChanged: widget.onEndDateChanged,
            ),
            _buildDivider(),
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildRepeatSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDaySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n.allDayLabel, style: context.textTheme.bodyMedium),
          AppSwitch(
            value: _allDay,
            onChanged: (value) {
              setState(() => _allDay = value);
              widget.onAllDayChanged(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: ElevatedButton(
        onPressed: context.pop,
        child: Text('Done'.toUpperCase()),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Divider(
        color: context.colorScheme.outline,
        height: UiConstants.borderWidth,
      ),
    );
  }

  Widget _buildRepeatSection(BuildContext context) {
    return Row(
      children: [
        Text(context.l10n.repeats, style: context.textTheme.bodyMedium),
        const Spacer(),
        PopupMenuButton<RepeatFrequency>(
          initialValue: _repeatFrequency,
          splashRadius: 0,
          color: context.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: UiConstants.borderRadius,
            side: BorderSide(
              color: context.colorScheme.outline,
              width: UiConstants.borderWidth,
            ),
          ),
          onSelected: (value) {
            setState(() => _repeatFrequency = value);
            widget.onRepeatRuleChanged(
              widget.repeatRule.copyWith(frequency: value),
            );
          },
          elevation: 0,
          itemBuilder: (context) => RepeatFrequency.values
              .map(
                (e) => PopupMenuItem(
                  value: e,
                  height: 36,
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Text(
                    e.label,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          child: Text(
            _repeatFrequency.label,
            style: context.textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Icon(Symbols.keyboard_arrow_down),
      ],
    );
  }
}
