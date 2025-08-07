import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/day_of_week.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/ui/features/calendar_event_details/calendar_event_details_cubit.dart';
import 'package:bebi_app/ui/features/calendar_event_details/widgets/delete_event_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      context,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child:
              BlocSelector<
                CalendarEventDetailsCubit,
                CalendarEventDetailsState,
                bool
              >(
                selector: (state) => state is CalendarEventDetailsStateLoading,
                builder: (context, loading) {
                  return OutlinedButton(
                    onPressed: !loading
                        ? () async {
                            final updatedEvent = await context
                                .pushNamed<CalendarEvent>(
                                  AppRoutes.updateCalendarEvent,
                                  extra: _event,
                                  pathParameters: {'id': _event.id},
                                );
                            if (updatedEvent != null) {
                              setState(() => _event = updatedEvent);
                            }
                          }
                        : null,
                    child: Text((loading ? 'Saving...' : 'Edit').toUpperCase()),
                  );
                },
              ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        _buildTitleSection(),
        _buildDateTimeSection(),
        if (_event.repeatRule.frequency != RepeatFrequency.doNotRepeat)
          _buildRepeatSection(),
        if (_event.location != null && _event.location!.isNotEmpty)
          _buildLocationSection(),
        if (_event.notes != null && _event.notes!.isNotEmpty)
          _buildNotesSection(),
        _buildDeleteButton(),
      ],
    );
  }

  Widget _buildTitleSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Expanded(
          child: Text(
            _event.title,
            style: context.primaryTextTheme.headlineSmall?.copyWith(
              color: _event.color.darken(0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Symbols.calendar_clock,
                  color: widget.calendarEvent.color.darken(0.1),
                ),
                const SizedBox(width: 16),
                Text(
                  _event.date.toEEEEMMMMdyyyy(),
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
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
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Row(
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
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Symbols.location_on,
                  color: widget.calendarEvent.color.darken(0.1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _event.location!,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Symbols.notes,
                  color: widget.calendarEvent.color.darken(0.1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _event.notes!,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Spacer(),
          const SizedBox(height: 32),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(UiConstants.padding),
              child:
                  BlocSelector<
                    CalendarEventDetailsCubit,
                    CalendarEventDetailsState,
                    bool
                  >(
                    selector: (state) =>
                        state is CalendarEventDetailsStateLoading,
                    builder: (context, loading) {
                      return TextButton(
                        style: TextButton.styleFrom(
                          textStyle: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          foregroundColor: context.colorScheme.error.darken(
                            0.1,
                          ),
                        ),
                        onPressed: loading ? null : _onDelete,
                        child: const Text('Delete event'),
                      );
                    },
                  ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Future<void> _onDelete() async {
    final result = await showDeleteEventBottomDialog(
      context,
      widget.calendarEvent,
    );

    if (result == DeleteEventResult.deleteThisEvent ||
        result == DeleteEventResult.deleteFutureEvents) {
      await context.read<CalendarEventDetailsCubit>().deleteCalendarEvent(
        widget.calendarEvent.id,
        deleteAllEvents: result == DeleteEventResult.deleteFutureEvents,
        instanceDate: widget.calendarEvent.date,
      );

      context.goNamed(
        AppRoutes.calendar,
        queryParameters: {'loadEventsFromServer': 'true'},
      );
    }
  }
}
