import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/cycles_setup/cycle_setup_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/ui/shared_widgets/switch/app_switch.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/string_extensions.dart';
import 'package:bebi_app/utils/formatters/date_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility_temp_fork/flutter_keyboard_visibility_temp_fork.dart';

class CyclesSetupScreen extends StatefulWidget {
  const CyclesSetupScreen({super.key});

  @override
  State<CyclesSetupScreen> createState() => _CyclesSetupScreenState();
}

class _CyclesSetupScreenState extends State<CyclesSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastPeriodDateController = TextEditingController();
  final _periodDurationController = TextEditingController();
  bool _shareWithPartner = true;

  @override
  void dispose() {
    _lastPeriodDateController.dispose();
    _periodDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CycleSetupCubit, CycleSetupState>(
      listener: (context, state) => switch (state) {
        CycleSetupErrorState(:final error) => context.showSnackbar(error),
        CycleSetupSuccessState() => context.pop(true),
        _ => null,
      },
      builder: (context, state) => KeyboardDismissOnTap(
        dismissOnCapturedTaps: true,
        child: Form(
          canPop: false,
          onPopInvokedWithResult: _onPop,
          key: _formKey,
          child: Scaffold(
            appBar: MainAppBar.build(context),
            body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                const SliverPadding(
                  padding: EdgeInsets.only(top: 24),
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                SliverToBoxAdapter(child: _buildLastPeriodDateField()),
                const SliverPadding(
                  padding: EdgeInsets.only(top: 16),
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                SliverToBoxAdapter(child: _buildPeriodDurationField()),
                const SliverPadding(
                  padding: EdgeInsets.only(top: 12),
                  sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
                ),
                SliverToBoxAdapter(child: _buildSharingOption()),
              ],
            ),
            bottomNavigationBar: _buildBottomSection(),
          ),
        ),
      ),
    );
  }

  void _onPop(bool didPop, Object? _) {
    if (didPop) return;

    Future.microtask(() async {
      final shouldPop = await OptionsBottomDialog.show(
        context,
        title: context.l10n.leaveWithoutSavingTitle,
        description: context.l10n.leaveWithoutSavingMessage,
        options: [
          Option(
            text: context.l10n.continueSetupButton,
            value: false,
            style: OptionStyle.primary,
          ),
          Option(text: context.l10n.leaveForNowButton, value: true),
        ],
      );

      if (shouldPop == true) context.pop();
    });
  }

  Widget _buildLastPeriodDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: AppTextFormField(
        controller: _lastPeriodDateController,
        labelText: context.l10n.lastPeriodLabel,
        hintText: 'MM/DD/YYYY',
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: const [DateInputFormatter()],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.l10n.lastPeriodRequired;
          }

          final date = value.toDateTime('MM/dd/yyyy');

          if (date == null) {
            return context.l10n.lastPeriodInvalid;
          }

          if (date.isAfter(DateTime.now())) {
            return context.l10n.lastPeriodFuture;
          }

          return null;
        },
      ),
    );
  }

  Widget _buildPeriodDurationField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: AppTextFormField(
        controller: _periodDurationController,
        labelText: context.l10n.periodDurationLabel,
        hintText: context.l10n.periodDurationHint,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.l10n.periodDurationRequired;
          }

          final duration = int.tryParse(value);

          if (duration == null) {
            return context.l10n.periodDurationInvalid;
          }

          if (duration <= 0 || duration > 10) {
            return context.l10n.periodDurationRange;
          }

          return null;
        },
      ),
    );
  }

  Widget _buildSharingOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                context.l10n.shareWithPartnerLabel,
                style: context.textTheme.bodyMedium,
              ),
              const Spacer(),
              AppSwitch(
                value: _shareWithPartner,
                onChanged: (value) => setState(() => _shareWithPartner = value),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.shareWithPartnerDescription,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.secondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        UiConstants.padding,
        UiConstants.padding,
        UiConstants.padding,
        0,
      ),
      child: Text(
        context.l10n.cycleSetupTitle,
        style: context.primaryTextTheme.headlineSmall,
      ),
    );
  }

  Widget _buildBottomSection() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.padding),
        child: BlocSelector<CycleSetupCubit, CycleSetupState, bool>(
          selector: (state) => state is CycleSetupLoadingState,
          builder: (context, loading) {
            return ElevatedButton(
              onPressed: loading
                  ? null
                  : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        context.read<CycleSetupCubit>().setUpCycleTracking(
                          periodStartDate: _lastPeriodDateController.text
                              .toDateTime('MM/dd/yyyy')!,
                          periodDurationInDays: int.parse(
                            _periodDurationController.text,
                          ),
                          shouldShareWithPartner: _shareWithPartner,
                        );
                      }
                    },
              child: Text(
                (loading ? context.l10n.savingButton : context.l10n.saveButton)
                    .toUpperCase(),
              ),
            );
          },
        ),
      ),
    );
  }
}
