import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/calendar/calendar_cubit.dart';
import 'package:bebi_app/ui/features/calendar/widgets/calendar.dart';
import 'package:bebi_app/ui/features/calendar/widgets/calendar_events.dart';
import 'package:bebi_app/ui/shared_widgets/buttons/app_icon_button.dart';
import 'package:bebi_app/ui/shared_widgets/buttons/app_text_button.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final _cubit = context.read<CalendarCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.initialize();
    // Load events from server after a couple seconds to refresh the cached data
    Future.delayed(3.seconds, () => _cubit.initialize(useCache: false));
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
    return Padding(
      padding: const EdgeInsets.only(
        left: UiConstants.padding,
        right: UiConstants.padding,
        top: 8,
      ),
      child: SafeArea(
        child: BlocSelector<CalendarCubit, CalendarState, DateTime>(
          selector: (state) => state.focusedDay,
          builder: (context, focusedDay) => Row(
            children: [
              Flexible(
                flex: 1,
                child: AnimatedSwitcher(
                  duration: 150.milliseconds,
                  child: focusedDay.isSameDay(DateTime.now())
                      ? Container()
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 38),
                            child: AppTextButton(
                              text: 'Today',
                              onTap: () => context
                                  .read<CalendarCubit>()
                                  .setFocusedDay(DateTime.now()),
                            ),
                          ),
                        ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Center(
                  child: Text(
                    focusedDay.toMMMMyyyy(),
                    style: context.primaryTextTheme.headlineSmall,
                  ),
                ),
              ),
              Flexible(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AppIconButton(
                    icon: Symbols.add,
                    onTap: () async {
                      final eventWasCreated = await context.pushNamed<bool>(
                        AppRoutes.createCalendarEvent,
                        queryParameters: {
                          'selectedDate': focusedDay.toIso8601String(),
                        },
                      );
                      if (eventWasCreated ?? false) {
                        _cubit.initialize(useCache: false);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
