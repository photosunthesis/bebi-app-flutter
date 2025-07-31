import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/day_of_week.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/ui/shared_widgets/buttons/app_text_button.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class CalendarEventDetailsScreen extends StatefulWidget {
  const CalendarEventDetailsScreen({required this.calendarEvent, super.key});

  final CalendarEvent calendarEvent;

  @override
  State<CalendarEventDetailsScreen> createState() =>
      _CalendarEventDetailsScreenState();
}

class _CalendarEventDetailsScreenState
    extends State<CalendarEventDetailsScreen> {
  late CalendarEvent _event = widget.calendarEvent;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    return MainAppBar.build(
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: AppTextButton(
            text: 'Edit',
            onTap: () async {
              final updatedEvent = await context.pushNamed<CalendarEvent>(
                AppRoutes.updateCalendarEvent,
                extra: _event,
                pathParameters: {'id': _event.id},
              );
              if (updatedEvent != null) {
                setState(() => _event = updatedEvent);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return ListView(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: UiConstants.padding),
                decoration: BoxDecoration(
                  color: _event.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _event.title,
                  style: context.primaryTextTheme.headlineSmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Icon(Symbols.calendar_clock),
              const SizedBox(width: 16),
              Text(
                _event.date.toEEEEMMMMdyyyy(),
                style: context.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Text(
                _event.allDay
                    ? 'All day'
                    : '${_event.startTimeLocal.toHHmma()} → ${_event.endTimeLocal!.toHHmma()}',
                style: context.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (_event.repeatRule.frequency != RepeatFrequency.doNotRepeat) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Text(
                  _event.repeatRule.frequency == RepeatFrequency.weekly
                      ? 'Repeats ${_event.repeatRule.frequency.name} (${_event.repeatRule.daysOfWeek?.map((e) => DayOfWeek.fromIndex(e).toTitle().substring(0, 3)).join(', ')})'
                      : 'Repeats ${_event.repeatRule.frequency.name}',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
        if (_event.location != null && _event.location!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Symbols.location_on),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _event.location!,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_event.notes != null && _event.notes!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Symbols.notes),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _event.notes!,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
