import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/kaomojis.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/app_update_info.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/ui/features/home/home_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/string_extensions.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
              fillOverscroll: false,
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    return BlocSelector<HomeCubit, HomeState, UserProfile?>(
      selector: (state) => state is HomeLoadedState ? state.currentUser : null,
      builder: (context, userProfile) {
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
                  userProfile?.displayName.toTitleCase() ?? 'user',
                ),
                style: context.primaryTextTheme.headlineSmall,
              ),
              Container(
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
                  backgroundImage: userProfile != null
                      ? CachedNetworkImageProvider(userProfile.photoUrl!)
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _kaomoji,
            style: context.textTheme.displaySmall?.copyWith(
              color: context.colorScheme.secondary.withAlpha(80),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _cubit.signOut,
                child: Text(context.l10n.signOutButton.toUpperCase()),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  context.pushNamed(AppRoutes.updatePassword);
                },
                child: Text(context.l10n.updatePasswordButton.toUpperCase()),
              ),
            ],
          ),
        ],
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
