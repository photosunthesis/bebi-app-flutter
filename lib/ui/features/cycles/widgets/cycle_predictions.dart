import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/cycles/cycles_cubit.dart';
import 'package:bebi_app/ui/features/cycles/widgets/angled_stripes_background.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:table_calendar/table_calendar.dart';

class CyclePredictions extends StatefulWidget {
  const CyclePredictions({super.key});

  @override
  State<CyclePredictions> createState() => _CyclePredictionsState();
}

class _CyclePredictionsState extends State<CyclePredictions> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.predictionsTitle,
            style: context.primaryTextTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          _buildFertileWindowPredictions(),
          const SizedBox(height: 24),
          _buildPeriodPredictions(),
        ],
      ),
    );
  }

  Widget _buildFertileWindowPredictions() {
    return BlocBuilder<CyclesCubit, CyclesState>(
      buildWhen: (previous, current) =>
          current.showCurrentUserCycleData !=
              previous.showCurrentUserCycleData ||
          current.focusedDateInsights != previous.focusedDateInsights,
      builder: (context, state) {
        return _buildCalendar(
          focusedDay:
              state.focusedDateInsights?.fertileDays.first ?? DateTime.now(),
          eventColor: AppColors.blue,
          title: context.l10n.fertilWindowTitle,
          description: state.showCurrentUserCycleData
              ? state.focusedDateInsights?.fertileDays.isNotEmpty == true
                    ? context.l10n.fertileWindowDescription(
                        state.focusedDateInsights!.fertileDays.first
                            .toEEEEMMMMd(),
                      )
                    : context.l10n.notEnoughDataFertileWindow
              : context.l10n.partnerNextPeriodDescription(
                  state.focusedDateInsights?.fertileDays.first.toEEEEMMMMd() ??
                      '',
                ),
          events: state.focusedDateInsights?.fertileDays ?? [],
        );
      },
    );
  }

  Widget _buildPeriodPredictions() {
    return BlocBuilder<CyclesCubit, CyclesState>(
      buildWhen: (previous, current) =>
          current.showCurrentUserCycleData !=
              previous.showCurrentUserCycleData ||
          current.focusedDateInsights != previous.focusedDateInsights,
      builder: (context, state) {
        return _buildCalendar(
          focusedDay:
              state.focusedDateInsights?.nextPeriodDates.first ??
              DateTime.now(),
          eventColor: AppColors.red,
          title: context.l10n.nextPeriodTitle,
          description: state.showCurrentUserCycleData
              ? state.focusedDateInsights?.nextPeriodDates.isNotEmpty == true
                    ? context.l10n.nextPeriodDescription(
                        state.focusedDateInsights!.nextPeriodDates.first
                            .toEEEEMMMMd(),
                      )
                    : context.l10n.notEnoughDataNextPeriod
              : context.l10n.partnerNextPeriodDescription(
                  state.focusedDateInsights?.nextPeriodDates.first
                          .toEEEEMMMMd() ??
                      '',
                ),
          events: state.focusedDateInsights?.nextPeriodDates ?? [],
        );
      },
    );
  }

  Widget _buildCalendar({
    required DateTime focusedDay,
    required Color eventColor,
    required String title,
    required String description,
    required List<DateTime> events,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 6),
        MarkdownBody(
          data: description,
          styleSheet: MarkdownStyleSheet(
            p: context.textTheme.bodyMedium,
            strong: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.secondary.withAlpha(10),
            borderRadius: UiConstants.borderRadius,
            border: Border.all(
              color: context.colorScheme.outline,
              width: UiConstants.borderWidth,
            ),
          ),
          child: TableCalendar(
            availableGestures: AvailableGestures.none,
            headerVisible: false,
            focusedDay: focusedDay,
            currentDay: focusedDay,
            firstDay: focusedDay.subtract(30.days),
            lastDay: focusedDay.add(365.days),
            daysOfWeekHeight: 24,
            calendarFormat: CalendarFormat.twoWeeks,
            daysOfWeekStyle: _dayOfWeekStyle(),
            calendarBuilders: CalendarBuilders(
              dowBuilder: _buildDayOfWeek,
              todayBuilder: (context, day, focusedDay) => _defaultDayBuilder(
                context,
                day,
                focusedDay,
                events,
                eventColor,
              ),
              defaultBuilder: (context, day, focusedDay) => _defaultDayBuilder(
                context,
                day,
                focusedDay,
                events,
                eventColor,
              ),
              outsideBuilder: (context, day, focusedDay) => _defaultDayBuilder(
                context,
                day,
                focusedDay,
                events,
                eventColor,
                true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _defaultDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
    List<DateTime> events,
    Color eventColor, [
    bool isOutside = false,
  ]) {
    final isSelected = events.any((e) => e.isSameDay(day));

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outline,
            width: UiConstants.borderWidth,
          ),
        ),
      ),
      child: Opacity(
        opacity: isOutside ? 0.3 : 1,
        child: Stack(
          children: [
            Center(
              child: AngledStripesBackground(
                color: isSelected
                    ? eventColor.withAlpha(90)
                    : Colors.transparent,
                backgroundColor: isSelected
                    ? eventColor.withAlpha(60)
                    : Colors.transparent,
              ),
            ),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: context.colorScheme.surface.withAlpha(140),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                  ],
                ),
                child: Text(
                  day.day.toString(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? eventColor.darken(0.3)
                        : context.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayOfWeek(BuildContext context, DateTime day) {
    return Center(
      child: Text(
        day.weekDayInitial,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.secondary,
        ),
      ),
    );
  }

  DaysOfWeekStyle _dayOfWeekStyle() {
    return DaysOfWeekStyle(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.onSecondary,
            width: UiConstants.borderWidth,
          ),
        ),
      ),
    );
  }
}
