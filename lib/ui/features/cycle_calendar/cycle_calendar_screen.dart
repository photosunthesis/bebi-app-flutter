import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/ui/features/cycle_calendar/cycle_calendar_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/custom/angled_stripes_background.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/color_extensions.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paged_vertical_calendar/paged_vertical_calendar.dart';

class CycleCalendarScreen extends StatefulWidget {
  const CycleCalendarScreen({required this.userId, super.key});

  final String userId;

  @override
  State<CycleCalendarScreen> createState() => _CycleCalendarScreenState();
}

class _CycleCalendarScreenState extends State<CycleCalendarScreen> {
  late final _scrollController = ScrollController();
  bool _showTodayButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CycleCalendarCubit>().initialize(widget.userId);
    });
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 50;
    if (shouldShow != _showTodayButton) {
      setState(() => _showTodayButton = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body:
          BlocSelector<CycleCalendarCubit, CycleCalendarState, List<CycleLog>>(
            selector: (state) =>
                state is CycleCalendarLoadedState ? state.cycleLogs : [],
            builder: (context, cycleLogs) {
              return PagedVerticalCalendar(
                scrollController: _scrollController,
                initialDate: DateTime.now(),
                monthBuilder: (context, month, year) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    DateTime(year, month).toMMMMyyyy(),
                    style: context.primaryTextTheme.titleLarge,
                  ),
                ),
                onDayPressed: context.pop,
                dayBuilder: (context, date) {
                  final [
                    periodLog,
                    ovulationLog,
                    symptomLog,
                    intimacyLog,
                  ] = LogType.values
                      .map(
                        (e) => cycleLogs.firstWhereOrNull(
                          (l) => l.type == e && l.date.isSameDay(date),
                        ),
                      )
                      .toList();
                  return _defaultDayBuilder(
                    date: date,
                    periodLog: periodLog,
                    ovulationLog: ovulationLog,
                    symptomLog: symptomLog,
                    intimacyLog: intimacyLog,
                  );
                },
              );
            },
          ),
    );
  }

  AppBar _buildAppBar() {
    return MainAppBar.build(
      context,
      actions: [
        AnimatedSwitcher(
          duration: 200.milliseconds,
          child: _showTodayButton
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: SizedBox(
                    width: 60,
                    child: OutlinedButton(
                      onPressed: () => _scrollController.animateTo(
                        0,
                        duration: 300.milliseconds,
                        curve: Curves.easeInOut,
                      ),
                      child: Text(context.l10n.todayButton.toUpperCase()),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _defaultDayBuilder({
    required DateTime date,
    CycleLog? periodLog,
    CycleLog? ovulationLog,
    CycleLog? symptomLog,
    CycleLog? intimacyLog,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outline,
            width: UiConstants.borderWidth,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Stack(
          children: [
            _buildDayBackground(periodLog, ovulationLog, date.isToday),
            _buildDayText(date, periodLog, ovulationLog),
            if (symptomLog != null || intimacyLog != null)
              _buildSymptomIndicator(symptomLog, intimacyLog),
          ],
        ),
      ),
    );
  }

  Widget _buildDayBackground(
    CycleLog? periodLog,
    CycleLog? ovulationLog,
    bool isToday,
  ) {
    final eventLog = periodLog ?? ovulationLog;
    final hasEvent = eventLog != null;

    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: isToday && hasEvent
              ? Border.all(color: eventLog.color, width: 2)
              : isToday
              ? Border.all(color: context.colorScheme.secondary, width: 2)
              : null,
          shape: BoxShape.circle,
        ),
        child: hasEvent && isToday
            ? Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.colorScheme.surface,
                    width: UiConstants.borderWidth,
                  ),
                  shape: BoxShape.circle,
                ),
                child: _buildEventContent(eventLog),
              )
            : _buildEventContent(eventLog),
      ),
    );
  }

  Widget _buildEventContent(CycleLog? eventLog) {
    return eventLog?.isPrediction == true
        ? AngledStripesBackground(
            color: eventLog!.color.withAlpha(90),
            backgroundColor: eventLog.color.withAlpha(60),
          )
        : SizedBox(
            width: 26,
            height: 26,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: eventLog?.color ?? Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          );
  }

  Widget _buildDayText(
    DateTime date,
    CycleLog? periodLog,
    CycleLog? ovulationLog,
  ) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            if ((periodLog ?? ovulationLog)?.isPrediction == true)
              BoxShadow(
                color: context.colorScheme.surface.withAlpha(140),
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
          ],
        ),
        child: Text(
          date.day.toString(),
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color:
                (periodLog ?? ovulationLog) != null &&
                    (periodLog ?? ovulationLog)!.isPrediction
                ? (periodLog ?? ovulationLog)!.color.darken(0.3)
                : (periodLog ?? ovulationLog) != null
                ? context.colorScheme.onPrimary
                : context.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomIndicator(CycleLog? symptomLog, CycleLog? intimacyLog) {
    return Positioned.fill(
      top: 40,
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          padding: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: symptomLog?.color ?? intimacyLog?.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
