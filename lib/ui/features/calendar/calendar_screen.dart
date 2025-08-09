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
  const CalendarScreen({this.shouldRefresh = false, super.key});

  final bool shouldRefresh;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final _cubit = context.read<CalendarCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.loadCalendarEvents();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldRefresh) _cubit.loadCalendarEvents();
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
            const Calendar(),
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
                      child: focusedDay.isToday
                          ? const SizedBox.shrink()
                          : OutlinedButton(
                              onPressed: () => context
                                  .read<CalendarCubit>()
                                  .setFocusedDay(DateTime.now()),
                              child: Text('Today'.toUpperCase()),
                            ),
                    ),
                    SizedBox(
                      width: 30,
                      child: OutlinedButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
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
                        child: const Icon(Symbols.add),
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
}
