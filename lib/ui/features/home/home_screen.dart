import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/kaomojis.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/app_update_info.dart';
import 'package:bebi_app/ui/features/home/home_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/string_extensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _cubit = context.read<HomeCubit>();
  static final _kaomoji = Kaomojis.getRandomFromHappySet();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cubit.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listener: (context, state) => switch (state) {
        HomeShouldConfirmEmailState() => context.goNamed(
          AppRoutes.confirmEmail,
        ),
        HomeShouldSetUpProfileState() => context.goNamed(
          AppRoutes.profileSetup,
        ),
        HomeShouldAddPartnerState() => context.goNamed(AppRoutes.addPartner),
        HomeShouldUpdateAppState(:final info) => _showAppUpdateDialog(info),
        HomeErrorState(:final message) => context.showSnackbar(message),
        _ => null,
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverSafeArea(
              sliver: SliverPadding(
                padding: const EdgeInsets.only(top: UiConstants.padding),
                sliver: SliverToBoxAdapter(child: Container()),
              ),
            ),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    return BlocSelector<HomeCubit, HomeState, User?>(
      selector: (state) => state is HomeLoadedState ? state.currentUser : null,
      builder: (context, user) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.l10n.homeGreeting(
                  now.hour < 12
                      ? context.l10n.morning
                      : now.hour < 17
                      ? context.l10n.afternoon
                      : context.l10n.evening,
                  user?.displayName?.toTitleCase() ?? 'user',
                ),
                style: context.primaryTextTheme.headlineSmall,
              ),
              _buildAccountMenu(user),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountMenu(User? user) {
    return PopupMenuButton(
      splashRadius: 0,
      color: context.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: UiConstants.borderRadius,
        side: BorderSide(
          color: context.colorScheme.outline,
          width: UiConstants.borderWidth,
        ),
      ),
      elevation: 0,
      offset: const Offset(0, 50),
      child: Container(
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
          backgroundImage: user != null
              ? CachedNetworkImageProvider(user.photoURL ?? '')
              : null,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.colorScheme.outline,
                      width: UiConstants.borderWidth,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: context.colorScheme.onTertiary,
                    backgroundImage: user?.photoURL != null
                        ? CachedNetworkImageProvider(user!.photoURL!)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'user',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: 'sign-out',
          child: Row(
            children: [
              const Icon(Symbols.exit_to_app, size: 20),
              const SizedBox(width: 10),
              Text(
                context.l10n.signOutButton.toUpperCase(),
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'update-password',
          child: Row(
            children: [
              const Icon(Symbols.lock, size: 20),
              const SizedBox(width: 10),
              Text(
                context.l10n.updatePasswordButton.toUpperCase(),
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) => switch (value) {
        'sign-out' => _onSignOut(),
        'update-password' => context.pushNamed(AppRoutes.updatePassword),
        'profile' => context.pushNamed(AppRoutes.profileSetup),
        _ => null,
      },
    );
  }

  Future<void> _onSignOut() async =>
      OptionsBottomDialog.show(
        context,
        title: context.l10n.signOutDialogTitle,
        description: context.l10n.signOutDialogDescription,
        options: [
          Option(
            text: context.l10n.signOutButton,
            value: true,
            style: OptionStyle.primary,
          ),
        ],
      ).then((value) async {
        if (value == true) await _cubit.signOut();
      });

  Widget _buildMainContent() {
    return Center(
      child: Text(
        _kaomoji,
        style: context.textTheme.displaySmall?.copyWith(
          color: context.colorScheme.secondary.withAlpha(80),
        ),
      ),
    );
  }

  void _showAppUpdateDialog(AppUpdateInfo info) {
    OptionsBottomDialog.show(
      context,
      isDismissible: false,
      enableDrag: false,
      title: context.l10n.newUpdateAvailableTitle,
      description: context.l10n.updateAvailableDescription(info.newVersion),
      options: [
        Option(
          text: context.l10n.downloadUpdateButton,
          value: true,
          style: OptionStyle.primary,
          onTap: () async => launchUrlString(
            info.downloadUrl,
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }
}
