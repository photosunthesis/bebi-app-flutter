import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/data/models/app_update_info.dart';
import 'package:bebi_app/ui/features/home/home_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _cubit = context.read<HomeCubit>();

  bool _showUpdateDialog = false;

  @override
  void initState() {
    super.initState();
    _cubit.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        // BlocListener not triggering state changes as expected 🤷🏻, using
        // BlocBuilder with manual state handling as workaround
        _handleStateChanges(state);

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.homeScreenTitle),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        await _cubit.signOut();
                        context.goNamed(AppRoutes.signIn);
                      },
                      child: Text(context.l10n.signOutButton.toUpperCase()),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {
                        context.pushNamed(AppRoutes.updatePassword);
                      },
                      child: Text(
                        context.l10n.updatePasswordButton.toUpperCase(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleStateChanges(HomeState state) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => switch (state) {
        HomeShouldSetUpProfile() => context.goNamed(AppRoutes.profileSetup),
        HomeShouldAddPartner() => context.goNamed(AppRoutes.addPartner),
        HomeShouldConfirmEmail() => context.goNamed(AppRoutes.confirmEmail),
        HomeShouldUpdateApp(:final info) => _showAppUpdateDialog(info),
        HomeError(:final message) => context.showSnackbar(message),
        _ => null,
      },
    );
  }

  void _showAppUpdateDialog(AppUpdateInfo info) {
    if (_showUpdateDialog) return;

    setState(() => _showUpdateDialog = true);

    OptionsBottomDialog.show(
      context,
      isDismissible: false,
      enableDrag: false,
      title: context.l10n.newUpdateAvailableTitle,
      description: context.l10n.updateAvailableDescription(info.newVersion),
      options: [
        Option(
          text: context.l10n.getUpdateButton,
          value: true,
          style: OptionStyle.primary,
          onTap: () async => launchUrlString(
            info.releaseUrl,
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }
}
