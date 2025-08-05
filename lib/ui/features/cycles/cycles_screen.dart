import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/ui/features/cycles/cycles_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    _cubit.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CyclesCubit, CyclesState>(
      listener: (context, state) {
        if (state.shouldSetupCycles) _showCycleSetupBottomSheet();
      },
      child: const Scaffold(),
    );
  }

  Future<void> _showCycleSetupBottomSheet() async {
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
  }
}
