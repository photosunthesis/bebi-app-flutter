import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/ui/features/log_intimacy/log_intimacy_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class LogIntimacyScreen extends StatefulWidget {
  const LogIntimacyScreen({
    required this.date,
    required this.logForPartner,
    this.cycleLogId,
    this.intimacyType,
    super.key,
  });

  final DateTime date;
  final bool logForPartner;
  final String? cycleLogId;
  final IntimacyType? intimacyType;

  @override
  State<LogIntimacyScreen> createState() => _LogIntimacyScreenState();
}

class _LogIntimacyScreenState extends State<LogIntimacyScreen> {
  late IntimacyType _intimacyType =
      widget.intimacyType ?? IntimacyType.protected;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogIntimacyCubit, LogIntimacyState>(
      listener: (context, state) => switch (state) {
        LogIntimacySuccessState() => context.pop(true),
        LogIntimacyErrorState(:final error) => context.showSnackbar(
          error,
          type: SnackbarType.error,
        ),
        _ => null,
      },
      builder: (context, state) {
        final loading = state is LogIntimacyLoadingState;
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
                context.l10n.logIntimacyTitle,
                style: context.primaryTextTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UiConstants.padding,
              ),
              child: Text(
                context.l10n.logIntimacySubtitle,
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
              color: AppColors.purple.withAlpha(50),
              borderRadius: UiConstants.borderRadius,
              border: Border.all(
                color: AppColors.purple.darken(0.4),
                width: UiConstants.borderWidth,
              ),
            ),
            child: Column(
              children: IntimacyType.values.expand((type) {
                final isLast = type == IntimacyType.values.last;
                return [
                  InkWell(
                    onTap: loading
                        ? null
                        : () => setState(() => _intimacyType = type),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type == IntimacyType.protected
                                ? context.l10n.protectedIntimacy
                                : context.l10n.unprotectedIntimacy,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: AppColors.purple.darken(0.4),
                            ),
                          ),
                          if (_intimacyType == type)
                            Icon(
                              Symbols.check,
                              size: 18,
                              color: AppColors.purple.darken(0.4),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Divider(
                        color: AppColors.purple.darken(0.4),
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
            : () async => await context.read<LogIntimacyCubit>().logIntimacy(
                cycleLogId: widget.cycleLogId,
                date: widget.date,
                intimacyType: _intimacyType,
                logForPartner: widget.logForPartner,
              ),
        child: Text(
          (loading
                  ? context.l10n.loggingIntimateActivityButton
                  : context.l10n.logIntimateActivityButton)
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
            : () async => await context.read<LogIntimacyCubit>().delete(
                widget.cycleLogId!,
              ),
        child: Text(
          (loading
                  ? context.l10n.deletingIntimateActivityButton
                  : context.l10n.deleteIntimateActivityButton)
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
