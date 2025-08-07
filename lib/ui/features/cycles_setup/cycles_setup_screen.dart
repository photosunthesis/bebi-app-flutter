import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/cycles_setup/cycle_setup_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/ui/shared_widgets/switch/app_switch.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/string_extensions.dart';
import 'package:bebi_app/utils/formatter/date_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      listener: (context, state) {
        if (state is CycleSetupStateSuccess) context.goNamed(AppRoutes.cycles);
        if (state is CycleSetupStateError) context.showSnackbar(state.error);
      },
      builder: (context, state) => Form(
        canPop: false,
        onPopInvokedWithResult: _onPop,
        key: _formKey,
        child: Scaffold(
          appBar: _buildAppbar(),
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
    );
  }

  void _onPop(bool didPop, Object? _) {
    if (didPop) return;

    Future.microtask(() async {
      final shouldPop = await OptionsBottomDialog.show(
        context,
        title: 'Leave without saving?',
        description:
            'Your cycle tracking setup is incomplete. You can come back and finish setting it up anytime.',
        options: const [
          Option(
            text: 'Continue setting up',
            value: false,
            style: OptionStyle.primary,
          ),
          Option(text: 'Leave for now', value: true),
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
        labelText: 'When did your last period start?',
        hintText: 'MM/DD/YYYY',
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: const [DateInputFormatter()],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your last period date.';
          }

          final date = value.toDateTime('MM/dd/yyyy');

          if (date == null) {
            return 'Please enter a valid date in MM/DD/YYYY format.';
          }

          if (date.isAfter(DateTime.now())) {
            return 'Last period date cannot be in the future.';
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
        labelText: 'How many days does your period usually last?',
        hintText: 'e.g. 6 days',
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the duration of your period in days.';
          }

          final duration = int.tryParse(value);

          if (duration == null) {
            return 'Please enter a valid number.';
          }

          if (duration <= 0 || duration > 10) {
            return 'Period duration should be between 1-10 days.';
          }

          return null;
        },
      ),
    );
  }

  Widget _buildSharingOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Row(
        children: [
          Text(
            'Share cycle data with partner',
            style: context.textTheme.bodyMedium,
          ),
          const Spacer(),
          AppSwitch(
            value: _shareWithPartner,
            onChanged: (value) => setState(() => _shareWithPartner = value),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppbar() {
    return MainAppBar.build(
      context,
      actions: [
        BlocSelector<CycleSetupCubit, CycleSetupState, bool>(
          selector: (state) => state is CycleSetupStateLoading,
          builder: (context, loading) {
            return TextButton(
              style: TextButton.styleFrom(
                textStyle: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
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
              child: Text(loading ? 'Saving' : 'Save'),
            );
          },
        ),
      ],
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
        'Cycle Tracking Setup',
        style: context.primaryTextTheme.headlineSmall,
      ),
    );
  }

  Widget _buildBottomSection() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.padding),
        child: Text(
          'We\'ll help you track your cycles with AI-powered insights, though the insights and predictions may not always be accurate. For any health concerns, it\'s best to check with your doctor. Additionally, you can always update your sharing preferences with your partner anytime.',
          style: context.textTheme.bodySmall?.copyWith(
            height: 1.4,
            color: context.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
