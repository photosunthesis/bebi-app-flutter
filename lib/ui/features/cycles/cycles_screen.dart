import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/ui/features/cycles/cycles_cubit.dart';
import 'package:bebi_app/ui/features/cycles/widgets/cycle_calendar.dart';
import 'package:bebi_app/ui/features/cycles/widgets/cycle_log_section.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class CyclesScreen extends StatefulWidget {
  const CyclesScreen({required this.shouldReinitialize, super.key});

  final bool shouldReinitialize;

  @override
  State<CyclesScreen> createState() => _CyclesScreenState();
}

class _CyclesScreenState extends State<CyclesScreen> {
  late final _cubit = context.read<CyclesCubit>();
  bool _cycleSetupBottomSheetIsShown = false;

  @override
  void initState() {
    super.initState();
    _cubit.initialize();
  }

  @override
  void didUpdateWidget(CyclesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldReinitialize) _cubit.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CyclesCubit, CyclesState>(
      listener: (context, state) {
        if (state.shouldSetupCycles && !_cycleSetupBottomSheetIsShown) {
          _showCycleSetupBottomSheet();
        }
      },
      child: Scaffold(
        body: ListView(
          children: [
            _buildHeader(),
            const CycleCalendar(),
            const SizedBox(height: 12),
            const CycleLogSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: BlocSelector<CyclesCubit, CyclesState, DateTime>(
        selector: (state) => state.focusedDate,
        builder: (context, date) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDateControls(date),
              Icon(Symbols.arrow_drop_down, color: context.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateControls(DateTime date) {
    return Stack(
      children: [
        _buildNavigationButtons(date),
        Positioned.fill(
          child: Center(
            child: Text(
              date.toEEEEMMMd(),
              style: context.primaryTextTheme.headlineSmall,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_buildTodayButton(date), _buildAccountSwitcher()],
      ),
    );
  }

  Widget _buildTodayButton(DateTime date) {
    return AnimatedSwitcher(
      duration: 120.milliseconds,
      child: date.isToday
          ? const SizedBox(height: 30)
          : SizedBox(
              key: const Key('today_button'),
              height: 30,
              child: OutlinedButton(
                onPressed: () => _cubit.setFocusedDate(DateTime.now()),
                child: Text('Today'.toUpperCase()),
              ),
            ),
    );
  }

  Widget _buildAccountSwitcher() {
    return BlocBuilder<CyclesCubit, CyclesState>(
      buildWhen: (p, c) =>
          p.showUserProfile != c.showUserProfile ||
          p.userProfile != c.userProfile ||
          p.partnerProfile != c.partnerProfile,
      builder: (context, state) {
        return InkWell(
          onTap: _cubit.switchUserProfile,
          splashFactory: NoSplash.splashFactory,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.5,
                  child: Transform.translate(
                    offset: const Offset(16, 0),
                    child: _buildProfileAvatar(
                      state.showUserProfile
                          ? state.partnerProfile
                          : state.userProfile,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: 120.milliseconds,
                  child: _buildProfileAvatar(
                    state.showUserProfile
                        ? state.userProfile
                        : state.partnerProfile,
                    key: ValueKey(state.showUserProfile),
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colorScheme.outline,
          width: UiConstants.borderWidth,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: context.colorScheme.secondary.withAlpha(40),
        backgroundImage: profile != null
            ? CachedNetworkImageProvider(profile.photoUrl!)
            : null,
      ),
    );
  }

  Future<void> _showCycleSetupBottomSheet() async {
    _cycleSetupBottomSheetIsShown = true;
    // Fake delay :D
    await Future.delayed(600.milliseconds, () {});

    final shouldSetup = await OptionsBottomDialog.show(
      context,
      title: 'Cycle tracking',
      isDismissible: false,
      description:
          'Track your menstrual cycle and get period and fertility predictions. Receive personalized insights from Google Gemini based on your cycle data. Choose to keep your information private or share with your partner.',
      options: [
        const Option(
          text: 'Set up cycle tracking',
          value: true,
          style: OptionStyle.primary,
        ),
        const Option(
          text: 'Don\'t track my cycle',
          value: false,
          style: OptionStyle.secondary,
        ),
      ],
    );

    if (shouldSetup == true) {
      await context.pushNamed(AppRoutes.cyclesSetup);
    } else {
      await _cubit.disableUserCycleTracking();
    }

    _cycleSetupBottomSheetIsShown = false;
  }
}
