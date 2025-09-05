import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/calendar/calendar_cubit.dart';
import 'package:bebi_app/ui/features/calendar/widgets/calendar.dart';
import 'package:bebi_app/ui/features/calendar/widgets/calendar_events.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/platform/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({this.routeState, super.key});

  final GoRouterState? routeState;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final _cubit = context.read<CalendarCubit>();
  bool get _shouldReloadEventsFromServer =>
      widget.routeState?.uri.queryParameters['loadEventsFromServer'] == 'true';

  @override
  void initState() {
    super.initState();
    _cubit.loadCalendarEvents();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldReloadEventsFromServer) {
      _cubit.loadCalendarEvents(useCache: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CalendarCubit, CalendarState>(
      listenWhen: (previous, current) => previous.events != current.events,
      listener: (context, state) => state.events.map(
        error: (error) =>
            context.showSnackbar(error.toString(), type: SnackbarType.error),
        orElse: () {},
      ),
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(),
          body: RefreshIndicator.adaptive(
            onRefresh: () async => _cubit.loadCalendarEvents(useCache: false),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: Calendar()),
                (state.focusedDayEvents.isNotEmpty)
                    ? CalendarEvents.buildList(state.focusedDayEvents)
                    : CalendarEvents.buildEmptyPlaceholder(context),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return MainAppBar.build(
      context,
      flexibleSpace: Center(child: _buildTitle()),
      toolbarHeight: 40 * ((kIsPwa && kIsWebiOS) || kIsAndroid ? 1.2 : 1),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTitle() {
    return SafeArea(
      child: BlocSelector<CalendarCubit, CalendarState, DateTime?>(
        selector: (state) => state.focusedDay,
        builder: (context, focusedDay) => SizedBox(
          height: 30,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UiConstants.padding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: 120.milliseconds,
                      child: focusedDay?.isToday == true || focusedDay == null
                          ? const SizedBox.shrink()
                          : OutlinedButton(
                              onPressed: () =>
                                  _cubit.setFocusedDay(DateTime.now()),
                              child: Text(
                                context.l10n.todayButton.toUpperCase(),
                              ),
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
                              'selectedDate': focusedDay
                                  ?.withRoundedOffTime()
                                  .toIso8601String(),
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
                child: Text(
                  focusedDay?.toMMMMyyyy() ?? '',
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
