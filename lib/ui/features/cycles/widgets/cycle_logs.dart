import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/ui/features/cycles/cycles_cubit.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class CycleLogs extends StatefulWidget {
  const CycleLogs({super.key});

  @override
  State<CycleLogs> createState() => _CycleLogsState();
}

class _CycleLogsState extends State<CycleLogs> {
  late final _cubit = context.read<CyclesCubit>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Logs', style: context.primaryTextTheme.titleLarge),
          const SizedBox(height: 18),
          _buildPeriodSection(),
          const SizedBox(height: 16),
          _buildOtherDataSection(),
        ],
      ),
    );
  }

  Widget _buildPeriodSection() {
    return BlocBuilder<CyclesCubit, CyclesState>(
      builder: (context, state) {
        final periodLog = state.focusedDateLogs.firstWhereOrNull(
          (e) => e.type == LogType.period,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Period'.toUpperCase(),
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final shouldRefresh = await context.pushNamed(
                  AppRoutes.logMenstrualCycle,
                  queryParameters: {
                    'logForPartner': '!${state.showCurrentUserCycleData}',
                    'date': state.focusedDate.toIso8601String(),
                    if (periodLog != null)
                      'flowIntensity': periodLog.flow!.name,
                  },
                );

                if (shouldRefresh == true) _cubit.refreshData();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withAlpha(60),
                  borderRadius: UiConstants.borderRadius,
                  border: Border.all(
                    color: AppColors.red.darken(0.4),
                    width: UiConstants.borderWidth,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menstrual Flow',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.red.darken(0.4),
                      ),
                    ),
                    if (state.focusedDateLogs.any(
                      (e) => e.type == LogType.period,
                    ))
                      Text(
                        state.focusedDateLogs
                            .firstWhere((e) => e.type == LogType.period)
                            .flow!
                            .label,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: AppColors.red.darken(0.15),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Icon(
                        Symbols.add_2,
                        size: 16,
                        color: AppColors.red.darken(0.4),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOtherDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Other logs'.toUpperCase(),
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.purple.withAlpha(50),
            borderRadius: UiConstants.borderRadius,
            border: Border.all(
              color: AppColors.purple.darken(0.4),
              width: UiConstants.borderWidth,
            ),
          ),
          child: Column(
            children: [
              _buildSymptomSection(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Divider(
                  color: AppColors.purple.darken(0.4),
                  height: UiConstants.borderWidth,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sexual Activity',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.purple.darken(0.4),
                      ),
                    ),
                    Icon(
                      Symbols.add_2,
                      size: 16,
                      color: AppColors.purple.darken(0.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomSection() {
    return BlocBuilder<CyclesCubit, CyclesState>(
      builder: (context, state) {
        final symptomLog = state.focusedDateLogs.firstWhereOrNull(
          (e) => e.type == LogType.symptom,
        );

        return InkWell(
          onTap: () async {
            final shouldRefresh = await context.pushNamed(
              AppRoutes.logSymptoms,
              queryParameters: {
                'logForPartner': '!${state.showCurrentUserCycleData}',
                'date': state.focusedDate.toIso8601String(),
                if (symptomLog != null)
                  'symptoms': symptomLog.symptoms?.join(',') ?? '',
              },
            );

            if (shouldRefresh == true) _cubit.refreshData();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Symptoms',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.purple.darken(0.4),
                  ),
                ),
                if (symptomLog != null)
                  Text(
                    symptomLog.symptoms != null &&
                            symptomLog.symptoms!.length > 2
                        ? '${symptomLog.symptoms!.first}, ${symptomLog.symptoms!.length - 1} more'
                        : symptomLog.symptoms?.join(', ') ?? '',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: AppColors.purple.darken(0.15),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Icon(
                    Symbols.add_2,
                    size: 16,
                    color: AppColors.purple.darken(0.4),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
