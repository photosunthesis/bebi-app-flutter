import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/symptoms.dart';
import 'package:bebi_app/ui/features/log_symptoms/log_symptoms_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/color_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogSymptomsScreen extends StatefulWidget {
  const LogSymptomsScreen({
    required this.date,
    required this.logForPartner,
    this.symptoms = const [],
    this.cycleLogId,
    super.key,
  });

  final DateTime date;
  final bool logForPartner;
  final List<String> symptoms;
  final String? cycleLogId;

  @override
  State<LogSymptomsScreen> createState() => _LogSymptomsScreenState();
}

class _LogSymptomsScreenState extends State<LogSymptomsScreen> {
  late final _symptoms = widget.symptoms;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogSymptomsCubit, LogSymptomsState>(
      listener: (context, state) => switch (state) {
        LogSymptomsSuccessState() => context.pop(true),
        LogSymptomsErrorState(:final error) => context.showSnackbar(
          error,
          type: SnackbarType.error,
        ),
        _ => null,
      },
      builder: (context, state) {
        final loading = state is LogSymptomsLoadingState;
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
                context.l10n.logSymptomsTitle,
                style: context.primaryTextTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UiConstants.padding,
              ),
              child: Text(
                context.l10n.logSymptomsSubtitle,
                style: context.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            _buildSelection(loading),
            _buildConfirmButton(loading),
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: Symptoms.values
                .map((e) => _buildSymptomItem(e.label))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomItem(String symptom) {
    final selected = _symptoms.contains(symptom);

    return InkWell(
      onTap: () => setState(() {
        if (selected) {
          _symptoms.remove(symptom);
        } else {
          _symptoms.add(symptom);
        }
      }),
      child: AnimatedSize(
        duration: 120.milliseconds,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.purple.withAlpha(selected ? 255 : 50),
            borderRadius: UiConstants.borderRadius,
            border: Border.all(
              color: AppColors.purple.darken(0.4),
              width: UiConstants.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                symptom,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? context.colorScheme.onPrimary
                      : AppColors.purple.darken(0.2),
                  fontWeight: selected ? FontWeight.w500 : null,
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.check,
                    size: 20,
                    color: context.colorScheme.onPrimary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(bool loading) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.padding),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colorScheme.primary,
            foregroundColor: context.colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 44),
          ),
          onPressed: loading
              ? null
              : () async => await context.read<LogSymptomsCubit>().logSymptoms(
                  cycleLogId: widget.cycleLogId,
                  date: widget.date,
                  logForPartner: widget.logForPartner,
                  symptoms: _symptoms,
                ),
          child: Text(
            loading
                ? context.l10n.loggingSymptomsButton.toUpperCase()
                : context.l10n.logSymptomsButton.toUpperCase(),
          ),
        ),
      ),
    );
  }
}
