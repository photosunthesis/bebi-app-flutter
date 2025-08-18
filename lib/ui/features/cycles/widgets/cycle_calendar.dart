import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/ui/features/cycles/cycles_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/custom/angled_stripes_background.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CycleCalendar extends StatefulWidget {
  const CycleCalendar({super.key});

  @override
  State<CycleCalendar> createState() => _CycleCalendarState();
}

class _CycleCalendarState extends State<CycleCalendar> {
  late List<DateTime> _dates;
  late final _cubit = context.read<CyclesCubit>();
  final _pageController = PageController(
    initialPage: _initialIndex,
    viewportFraction: 1.0 / _daysToShow,
  );

  static const _initialIndex = 1000;
  static const _daysToShow = 7;

  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _generateDates();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _generateDates() {
    _dates = [];
    final startDate = DateTime.now().subtract(_initialIndex.days);

    for (var i = 0; i < _initialIndex * 2; i++) {
      _dates.add(startDate.add(i.days));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CyclesCubit, CyclesState>(
      listener: (context, state) {
        // Only respond to "back to today" button presses to avoid unnecessary
        // page animations from other focus date changes
        if (!state.focusedDate.isToday) return;
        if (_isTransitioning) return;

        final targetIndex = _dates.indexWhere(
          (d) => d.isSameDay(state.focusedDate),
        );

        if (targetIndex != -1) {
          _isTransitioning = true;
          _pageController
              .animateToPage(
                targetIndex,
                duration: 200.milliseconds,
                curve: Curves.easeOutCubic,
              )
              .then((_) {
                _isTransitioning = false;
              });
        }
      },
      child: SizedBox(
        height: 85,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            if (index < _dates.length) {
              Future.delayed(200.milliseconds, () {
                if (mounted && _pageController.page?.round() == index) {
                  _cubit.setFocusedDate(_dates[index]);
                }
              });
            }
          },
          itemBuilder: (context, index) {
            return index >= _dates.length
                ? const SizedBox.shrink()
                : _buildDayItem(date: _dates[index]);
          },
        ),
      ),
    );
  }

  Widget _buildDayItem({required DateTime date}) {
    return BlocSelector<CyclesCubit, CyclesState, List<CycleLog>>(
      selector: (state) => state.cycleLogs,
      builder: (context, cycleLogs) {
        final [periodLog, ovulationLog, symptomLog, intimacyLog] = LogType
            .values
            .map(
              (e) => cycleLogs.firstWhereOrNull(
                (l) => l.type == e && l.date.isSameDay(date),
              ),
            )
            .toList();

        return InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () async => _handleDayTap(date),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWeekDay(date),
              const SizedBox(height: 4),
              _buildDivider(),
              const SizedBox(height: 4),
              _buildDateIndicator(
                date: date,
                periodLog: periodLog,
                ovulationLog: ovulationLog,
                symptomLog: symptomLog,
                intimacyLog: intimacyLog,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDayTap(DateTime date) async {
    final targetIndex = _dates.indexWhere((d) => d.isSameDay(date));
    if (targetIndex != -1) {
      await _pageController.animateToPage(
        targetIndex,
        duration: 200.milliseconds,
        curve: Curves.easeOutCubic,
      );
    }
    // await _cubit.setFocusedDate(date);
  }

  Widget _buildWeekDay(DateTime date) {
    return Text(
      date.toEEE(),
      style: context.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: context.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: UiConstants.borderWidth,
      color: context.colorScheme.outline,
    );
  }

  Widget _buildDateIndicator({
    required DateTime date,
    required CycleLog? periodLog,
    required CycleLog? ovulationLog,
    required CycleLog? symptomLog,
    required CycleLog? intimacyLog,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const SizedBox(width: 48, height: 48),
        if (periodLog != null || ovulationLog != null)
          _buildMainEventIndicator(periodLog, ovulationLog),
        if (symptomLog != null || intimacyLog != null)
          _buildSecondaryEventIndicator(symptomLog, intimacyLog),
        _buildDateText(date, periodLog, ovulationLog),
      ],
    );
  }

  Widget _buildMainEventIndicator(CycleLog? periodLog, CycleLog? ovulationLog) {
    final event = periodLog ?? ovulationLog;

    return Positioned(
      top: 5,
      child: event?.isPrediction ?? true
          ? AngledStripesBackground(
              color: event?.color.withAlpha(60) ?? Colors.transparent,
              backgroundColor: event?.color.withAlpha(40) ?? Colors.transparent,
              shape: const CircleBorder(),
            )
          : Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: event?.color,
              ),
            ),
    );
  }

  Widget _buildSecondaryEventIndicator(
    CycleLog? symptomLog,
    CycleLog? intimacyLog,
  ) {
    return Positioned(
      top: 36,
      child: AnimatedContainer(
        duration: 120.milliseconds,
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: symptomLog?.color ?? intimacyLog?.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildDateText(
    DateTime date,
    CycleLog? periodLog,
    CycleLog? ovulationLog,
  ) {
    final event = periodLog ?? ovulationLog;
    final textColor = event != null && !event.isPrediction
        ? context.colorScheme.surface
        : event?.isPrediction ?? false
        ? event?.color.darken(0.2)
        : context.colorScheme.primary;

    return Positioned(
      top: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            if (event?.isPrediction == true)
              BoxShadow(
                color: context.colorScheme.surface.withAlpha(140),
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
          ],
        ),
        child: Text(
          date.day.toString(),
          style: context.textTheme.titleMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
