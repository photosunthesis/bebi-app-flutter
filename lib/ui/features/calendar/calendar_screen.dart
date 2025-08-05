import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/calendar/calendar_cubit.dart';
import 'package:bebi_app/ui/features/calendar/widgets/calendar.dart';
import 'package:bebi_app/ui/features/calendar/widgets/calendar_events.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({this.shouldLoadEventsFromServer = false, super.key});

  final bool shouldLoadEventsFromServer;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final _cubit = context.read<CalendarCubit>();
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _cubit.loadCalendarEvents();

    // For some reason, rendering the calendar widget directly causes the tab
    // switching animation to stutter. Not entirely sure why, but showing a loading
    // skeleton first and delaying the calendar render makes the animation smooth.
    Future.delayed(
      600.milliseconds,
      () => setState(() => _showCalendar = true),
    );
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldLoadEventsFromServer) {
      _cubit.loadCalendarEvents(useCache: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalendarCubit, CalendarState>(
      listener: (context, state) {
        if (state.error != null) context.showSnackbar(state.error!);
      },
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: 300.milliseconds,
              child: _showCalendar
                  ? const Calendar()
                  : _buildCalendarSkeleton(),
            ),
            const CalendarEvents(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return SafeArea(
      child: BlocSelector<CalendarCubit, CalendarState, DateTime>(
        selector: (state) => state.focusedDay,
        builder: (context, focusedDay) => SizedBox(
          height: 30,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UiConstants.padding,
                  vertical: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: 120.milliseconds,
                      child: focusedDay.isSameDay(DateTime.now())
                          ? const SizedBox.shrink()
                          : SizedBox(
                              key: const ValueKey('today'),
                              width: 56,
                              height: 30,
                              child: TextButton(
                                onPressed: () => context
                                    .read<CalendarCubit>()
                                    .setFocusedDay(DateTime.now()),
                                child: const Text('Today'),
                              ),
                            ),
                    ),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Icon(Symbols.add),
                        onPressed: () async {
                          final eventWasCreated = await context.pushNamed<bool>(
                            AppRoutes.createCalendarEvent,
                            queryParameters: {
                              'selectedDate': focusedDay.toIso8601String(),
                            },
                          );
                          if (eventWasCreated == true) {
                            await _cubit.loadCalendarEvents();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  focusedDay.toMMMMyyyy(),
                  style: context.primaryTextTheme.headlineSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSkeleton() {
    return Column(
      children: [
        Container(
          height: 32,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.colorScheme.onSecondary,
                width: 0.2,
              ),
            ),
          ),
          child: Row(
            children: List.generate(7, (index) {
              return Expanded(
                child: Center(
                  child: Container(
                    width: 20,
                    height: 12,
                    decoration: BoxDecoration(
                      color: context.colorScheme.onSurface.withAlpha(40),
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        ...List.generate(6, (weekIndex) {
          return Container(
            height: 52,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.colorScheme.onSecondary,
                  width: UiConstants.borderWidth,
                ),
              ),
            ),
            child: Row(
              children: List.generate(7, (dayIndex) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(15, 10, 15, 18),
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: context.colorScheme.onSurface.withAlpha(40),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}
