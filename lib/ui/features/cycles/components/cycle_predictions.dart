import 'package:bebi_app/app/app_cubit.dart';
import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/dto/user_profile_with_picture_dto.dart';
import 'package:bebi_app/ui/features/cycles/cycles_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/specialized/angled_stripes_background.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/color_extensions.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.predictionsTitle,
                style: context.primaryTextTheme.titleLarge,
              ),
              _buildViewAllButton(),
            ],
          ),
          const SizedBox(height: 8),
          _buildFertileWindowPredictions(),
          const SizedBox(height: 24),
          _buildPeriodPredictions(),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return BlocSelector<
      AppCubit,
      AppState,
      (UserProfileWithPictureDto, UserProfileWithPictureDto)
    >(
      selector: (state) => (
        state.userProfileAsync.asData()!,
        state.partnerProfileAsync.asData()!,
      ),
      builder: (context, userProfiles) {
        final (userProfile, partnerProfile) = userProfiles;
        return BlocSelector<CyclesCubit, CyclesState, String?>(
          selector: (state) => state.isViewingCurrentUser
              ? userProfile.userId
              : partnerProfile.userId,
          builder: (context, userId) {
            return OutlinedButton(
              onPressed: () async {
                final selectedDate = await context.pushNamed(
                  AppRoutes.cycleCalendar,
                  queryParameters: {'userId': userId},
                );

                if (selectedDate is DateTime) {
                  await context.read<CyclesCubit>().setFocusedDate(
                    selectedDate,
                  );
                }
              },
              child: Text(context.l10n.viewAllButton.toUpperCase()),
            );
          },
        );
      },
    );
  }

  Widget _buildFertileWindowPredictions() {
    return BlocBuilder<CyclesCubit, CyclesState>(
      buildWhen: (previous, current) =>
          current.isViewingCurrentUser != previous.isViewingCurrentUser ||
          current.insights != previous.insights,
      builder: (context, state) {
        final fertileDays = state.insights.asData()?.fertileDays ?? [];

        late String description;
        if (state.isViewingCurrentUser) {
          if (fertileDays.isNotEmpty) {
            description = context.l10n.fertileWindowDescription(
              fertileDays.first.toEEEEMMMMd(),
            );
          } else {
            description = context.l10n.notEnoughDataFertileWindow;
          }
        } else {
          final dateString = fertileDays.isNotEmpty
              ? fertileDays.first.toEEEEMMMMd()
              : '';
          description = context.l10n.partnerFertileWindowDescription(
            dateString,
          );
        }

        return _buildCalendar(
          focusedDay: fertileDays.isNotEmpty
              ? fertileDays.first
              : DateTime.now(),
          eventColor: AppColors.blue,
          title: context.l10n.fertilWindowTitle,
          description: description,
          events: fertileDays,
        );
      },
    );
  }

  Widget _buildPeriodPredictions() {
    return BlocBuilder<CyclesCubit, CyclesState>(
      buildWhen: (previous, current) =>
          current.isViewingCurrentUser != previous.isViewingCurrentUser ||
          current.insights != previous.insights,
      builder: (context, state) {
        final nextPeriodDates = state.insights.asData()?.nextPeriodDates ?? [];

        late String description;
        if (state.isViewingCurrentUser) {
          if (nextPeriodDates.isNotEmpty) {
            description = context.l10n.nextPeriodDescription(
              nextPeriodDates.first.toEEEEMMMMd(),
            );
          } else {
            description = context.l10n.notEnoughDataNextPeriod;
          }
        } else {
          final dateString = nextPeriodDates.isNotEmpty
              ? nextPeriodDates.first.toEEEEMMMMd()
              : '';
          description = context.l10n.partnerNextPeriodDescription(dateString);
        }

        return _buildCalendar(
          focusedDay: nextPeriodDates.isNotEmpty
              ? nextPeriodDates.first
              : DateTime.now(),
          eventColor: AppColors.red,
          title: context.l10n.nextPeriodTitle,
          description: description,
          events: nextPeriodDates,
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
