import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/ui/features/cycles/cycles_cubit.dart';
import 'package:bebi_app/ui/features/cycles/widgets/cycle_calendar.dart';
import 'package:bebi_app/ui/features/cycles/widgets/cycle_insights.dart';
import 'package:bebi_app/ui/features/cycles/widgets/cycle_logs.dart';
import 'package:bebi_app/ui/features/cycles/widgets/cycle_predictions.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class CyclesScreen extends StatefulWidget {
  const CyclesScreen({super.key});

  @override
  State<CyclesScreen> createState() => _CyclesScreenState();
}

class _CyclesScreenState extends State<CyclesScreen> {
  late final _cubit = context.read<CyclesCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cubit.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CyclesCubit, CyclesState>(
      listener: (context, state) => switch (state) {
        CyclesErrorState() => context.showSnackbar(
          state.error,
          type: SnackbarType.primary,
          duration: 6.seconds,
        ),
        _ => null,
      },

      child: Scaffold(
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async =>
                  _cubit.initialize(loadDataFromCache: false),
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  const CycleLogs(),
                  const SizedBox(height: 32),
                  const CycleInsights(),
                  const SizedBox(height: 32),
                  const CyclePredictions(),
                  const SizedBox(height: 20),
                  _buildDisclaimer(),
                ],
              ),
            ),
            _buildCyclesSetupPrompt(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return MainAppBar.build(
      context,
      toolbarHeight: 138,
      flexibleSpace: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          const CycleCalendar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: BlocSelector<CyclesCubit, CyclesState, DateTime?>(
        selector: (state) =>
            state is CyclesLoadedState ? state.focusedDate : null,
        builder: (context, focusedDay) => Center(
          child: Stack(
            children: [
              _buildDateControls(focusedDay),
              Positioned.fill(
                top: 34,
                child: Icon(
                  Symbols.keyboard_arrow_down,
                  color: context.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateControls(DateTime? date) {
    return SizedBox(
      child: Stack(
        children: [
          _buildNavigationButtons(date),
          Positioned.fill(
            child: Center(
              child: Text(
                date?.isToday == true
                    ? 'Today, ${date!.toMMMMd()}'
                    : date?.toEEEEMMMd() ?? '',
                style: context.primaryTextTheme.headlineSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(DateTime? date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_buildTodayButton(date), _buildAccountSwitcher()],
      ),
    );
  }

  Widget _buildTodayButton(DateTime? date) {
    return AnimatedSwitcher(
      duration: 120.milliseconds,
      child: date?.isToday == true
          ? const SizedBox(height: 30)
          : SizedBox(
              key: const Key('today_button'),
              height: 30,
              child: OutlinedButton(
                onPressed: () => _cubit.setFocusedDate(DateTime.now()),
                child: Text(context.l10n.todayButton.toUpperCase()),
              ),
            ),
    );
  }

  Widget _buildAccountSwitcher() {
    return BlocBuilder<CyclesCubit, CyclesState>(
      buildWhen: (previous, current) => current is CyclesLoadedState,
      builder: (context, state) {
        return InkWell(
          onTap: _cubit.switchUserProfile,
          splashFactory: NoSplash.splashFactory,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.4,
                  child: Transform.translate(
                    offset: const Offset(16, 0),
                    child: _buildProfileAvatar(
                      (state as CyclesLoadedState).showCurrentUserCycleData
                          ? state.partnerProfile
                          : state.userProfile,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: 120.milliseconds,
                  child: _buildProfileAvatar(
                    state.showCurrentUserCycleData
                        ? state.userProfile
                        : state.partnerProfile,
                    key: ValueKey(state.showCurrentUserCycleData),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(UserProfile? profile, {Key? key}) {
    return Container(
      key: key,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colorScheme.outline,
          width: UiConstants.borderWidth,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: context.colorScheme.onTertiary,
        backgroundImage: profile != null
            ? CachedNetworkImageProvider(profile.photoUrl!)
            : null,
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.all(UiConstants.padding),
      child: Text(
        context.l10n.cycleTrackingDisclaimer,
        style: context.textTheme.bodySmall?.copyWith(
          height: 1.4,
          color: context.colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildCyclesSetupPrompt() {
    return BlocSelector<CyclesCubit, CyclesState, bool>(
      selector: (state) => switch (state) {
        CyclesLoadedState() when !state.showCurrentUserCycleData => true,
        CyclesLoadedState() => state.userProfile?.hasCycle ?? true,
        _ => true,
      },
      builder: (context, hidePrompt) {
        return AnimatedSwitcher(
          duration: 120.milliseconds,
          child: hidePrompt
              ? const SizedBox.shrink()
              : Container(
                  key: const ValueKey('no_cycle_data'),
                  color: context.colorScheme.surface.withAlpha(200),
                  width: double.infinity,
                  height: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: context.colorScheme.surface.withAlpha(200),
                              blurRadius: 12,
                              offset: const Offset(0, 0),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          context.l10n.welcomeToCycleTrackingTitle,
                          style: context.primaryTextTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: context.colorScheme.surface.withAlpha(200),
                              blurRadius: 12,
                              offset: const Offset(0, 0),
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          context.l10n.welcomeToCycleTrackingMessage,
                          style: context.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () async {
                          final shouldReinitialize = await context.pushNamed(
                            AppRoutes.cyclesSetup,
                          );
                          if (shouldReinitialize == true) _cubit.refreshData();
                        },
                        child: Text(
                          context.l10n.setupCycleTrackingButton.toUpperCase(),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
