import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/ui/features/log_menstrual_flow/log_menstrual_flow_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class LogMenstrualFlowScreen extends StatefulWidget {
  const LogMenstrualFlowScreen({
    required this.date,
    required this.averagePeriodDurationInDays,
    required this.logForPartner,
    this.cycleLogId,
    this.flowIntensity,
    super.key,
  });

  final DateTime date;
  final int averagePeriodDurationInDays;
  final bool logForPartner;
  final String? cycleLogId;
  final FlowIntensity? flowIntensity;

  @override
  State<LogMenstrualFlowScreen> createState() => _LogMenstrualFlowScreenState();
}

class _LogMenstrualFlowScreenState extends State<LogMenstrualFlowScreen> {
  late FlowIntensity _flowIntensity =
      widget.flowIntensity ?? FlowIntensity.light;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogMenstrualFlowCubit, LogMenstrualFlowState>(
      listener: (context, state) => switch (state) {
        LogMenstrualFlowSuccessState() => context.pop(true),
        LogMenstrualFlowErrorState(:final error) => context.showSnackbar(
          error,
          type: SnackbarType.error,
        ),
        _ => null,
      },
      builder: (context, state) {
        final loading = state is LogMenstrualFlowLoadingState;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: context.colorScheme.outline.withAlpha(80),
                    borderRadius: UiConstants.borderRadius,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UiConstants.padding,
              ),
              child: Text(
                context.l10n.logMenstrualFlowTitle,
                style: context.primaryTextTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UiConstants.padding,
              ),
              child: Text(
                context.l10n.logMenstrualFlowSubtitle,
                style: context.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            _buildSelection(loading),
            const SizedBox(height: 16),
            _buildConfirmButton(loading),
            if (widget.cycleLogId != null) ...[
              const SizedBox(height: 4),
              _buildDeleteButton(loading),
            ],
            const SafeArea(child: SizedBox.shrink()),
          ],
        );
      },
    );
  }

  Widget _buildSelection(bool loading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.red.withAlpha(50),
              borderRadius: UiConstants.borderRadius,
              border: Border.all(
                color: AppColors.red.darken(0.4),
                width: UiConstants.borderWidth,
              ),
            ),
            child: Column(
              children: FlowIntensity.values.expand((intensity) {
                final isLast = intensity == FlowIntensity.values.last;
                return [
                  InkWell(
                    onTap: loading
                        ? null
                        : () => setState(() => _flowIntensity = intensity),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            switch (intensity) {
                              FlowIntensity.light => context.l10n.lightFlow,
                              FlowIntensity.medium => context.l10n.mediumFlow,
                              FlowIntensity.heavy => context.l10n.heavyFlow,
                            },
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: AppColors.red.darken(0.4),
                            ),
                          ),
                          if (_flowIntensity == intensity)
                            Icon(
                              Symbols.check,
                              size: 18,
                              color: AppColors.red.darken(0.4),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Divider(
                        color: AppColors.red.darken(0.4),
                        height: UiConstants.borderWidth,
                      ),
                    ),
                ];
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(bool loading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colorScheme.primary,
          foregroundColor: context.colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 44),
        ),
        onPressed: loading
            ? null
            : () async => await context.read<LogMenstrualFlowCubit>().logFlow(
                averagePeriodDurationInDays: widget.averagePeriodDurationInDays,
                cycleLogId: widget.cycleLogId,
                date: widget.date,
                flowIntensity: _flowIntensity,
                logForPartner: widget.logForPartner,
              ),
        child: Text(
          (loading
                  ? context.l10n.loggingMenstrualFlowButton
                  : context.l10n.logMenstrualFlowButton)
              .toUpperCase(),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(bool loading) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colorScheme.primary,
          minimumSize: const Size(double.infinity, 44),
        ),
        onPressed: loading
            ? null
            : () async => await context.read<LogMenstrualFlowCubit>().delete(
                widget.cycleLogId!,
              ),
        child: Text(
          (loading
                  ? context.l10n.deletingMenstrualFlowButton
                  : context.l10n.deleteMenstrualFlowButton)
              .toUpperCase(),
          style: context.textTheme.titleSmall?.copyWith(
            color: context.colorScheme.error,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
