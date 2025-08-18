import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/ui/features/cycles/cycles_cubit.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/color_extensions.dart';
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
          Text(
            context.l10n.logsTitle,
            style: context.primaryTextTheme.titleLarge,
          ),
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
      buildWhen: (previous, current) =>
          current.showCurrentUserCycleData !=
              previous.showCurrentUserCycleData ||
          current.focusedDateLogs != previous.focusedDateLogs,
      builder: (context, state) {
        final showCurrentUserCycleData = state.showCurrentUserCycleData;
        final periodLog = state.focusedDateLogs.firstWhereOrNull(
          (e) => e.type == LogType.period,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.bleedingTitle.toUpperCase(),
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
                    'logForPartner': '!$showCurrentUserCycleData',
                    'date': state.focusedDate.toIso8601String(),
                    'averagePeriodDurationInDays':
                        state.focusedDateInsights?.averagePeriodDurationInDays,
                    if (periodLog != null) ...{
                      'cycleLogId': periodLog.id,
                      'flowIntensity': periodLog.flow!.name,
                    },
                  },
                );

                if (shouldRefresh == true) await _cubit.refreshData();
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
                      context.l10n.menstrualFlowTitle,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.red.darken(0.4),
                      ),
                    ),
                    if (periodLog != null)
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
          context.l10n.otherLogsTitle.toUpperCase(),
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
              _buildLogSection(
                logType: LogType.symptom,
                title: context.l10n.symptomsTitle,
                routeName: AppRoutes.logSymptoms,
                getDisplayText: (log) => _getSymptomDisplayText(log),
                getRouteParams: (log) => {
                  'cycleLogId': log.id,
                  'symptoms': log.symptoms!.join(','),
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Divider(
                  color: AppColors.purple.darken(0.4),
                  height: UiConstants.borderWidth,
                ),
              ),
              _buildLogSection(
                logType: LogType.intimacy,
                title: context.l10n.intimateActivitiesTitle,
                routeName: AppRoutes.logIntimacy,
                getDisplayText: (log) =>
                    context.l10n.intimacySex(log.intimacyType!.label),
                getRouteParams: (log) => {
                  'cycleLogId': log.id,
                  'intimacyType': log.intimacyType!.name,
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogSection({
    required LogType logType,
    required String title,
    required String routeName,
    required String Function(CycleLog) getDisplayText,
    required Map<String, String> Function(CycleLog) getRouteParams,
  }) {
    return BlocBuilder<CyclesCubit, CyclesState>(
      buildWhen: (previous, current) =>
          current.focusedDateLogs != previous.focusedDateLogs,
      builder: (context, state) {
        final log = state.focusedDateLogs.firstWhereOrNull(
          (e) => e.type == logType,
        );

        return InkWell(
          onTap: () => _handleLogTap(state, routeName, log, getRouteParams),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.purple.darken(0.4),
                  ),
                ),
                if (log != null)
                  Text(
                    getDisplayText(log),
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

  String _getSymptomDisplayText(CycleLog log) {
    if (log.symptoms != null && log.symptoms!.length > 2) {
      return context.l10n.moreSymptoms(
        log.symptoms!.first,
        log.symptoms!.length - 1,
      );
    }
    return log.symptoms?.join(', ') ?? '';
  }

  Future<void> _handleLogTap(
    CyclesState state,
    String routeName,
    CycleLog? log,
    Map<String, String> Function(CycleLog) getRouteParams,
  ) async {
    final shouldRefresh = await context.pushNamed(
      routeName,
      queryParameters: {
        'logForPartner': '!${state.showCurrentUserCycleData}',
        'date': state.focusedDate.toIso8601String(),
        if (log != null) ...getRouteParams(log),
      },
    );

    if (shouldRefresh == true) await _cubit.refreshData();
  }
}
