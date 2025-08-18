import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/kaomojis.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/confirm_email/confirm_email_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConfirmEmailScreen extends StatefulWidget {
  const ConfirmEmailScreen({super.key});

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  late final _cubit = context.read<ConfirmEmailCubit>();
  static final _kaomoji = Kaomojis.getRandomFromHappySet();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cubit.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocListener<ConfirmEmailCubit, ConfirmEmailState>(
        listener: (context, state) => switch (state) {
          ConfirmEmailSuccessState() => context.goNamed(AppRoutes.home),
          ConfirmEmailErrorState(:final error) => context.showSnackbar(
            error,
            type: SnackbarType.secondary,
          ),
          _ => null,
        },
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              const SliverSafeArea(
                sliver: SliverToBoxAdapter(
                  child: SizedBox(height: UiConstants.padding),
                ),
              ),
              SliverToBoxAdapter(child: _buildHeader()),
              SliverFillRemaining(
                hasScrollBody: false,
                fillOverscroll: false,
                child: _buildKaomoji(),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.checkEmailTitle,
            style: context.primaryTextTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            child: BlocSelector<ConfirmEmailCubit, ConfirmEmailState, String?>(
              selector: (state) =>
                  state is ConfirmEmailLoadedState ? state.email : null,
              builder: (context, email) {
                final censoredEmail = _censorEmail(email ?? '');
                return RichText(
                  text: TextSpan(
                    style: context.textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                      fontWeight: FontWeight.normal,
                    ),
                    children: [
                      TextSpan(text: context.l10n.checkEmailMessagePrefix),
                      TextSpan(
                        text: censoredEmail,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: context.l10n.checkEmailMessageSuffix),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _censorEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex == -1) return email;

    final localPart = email.substring(0, atIndex);
    final domainPart = email.substring(atIndex + 1);

    final censoredLocal = localPart.length <= 3
        ? localPart
        : '${localPart.substring(0, 3)}***';

    final dotIndex = domainPart.lastIndexOf('.');
    if (dotIndex == -1) {
      final censoredDomain = domainPart.length <= 1
          ? domainPart
          : '${domainPart.substring(0, 1)}${'*' * (domainPart.length - 1)}';
      return '$censoredLocal@$censoredDomain';
    }

    final domainName = domainPart.substring(0, dotIndex);
    final domainExtension = domainPart.substring(dotIndex);
    final censoredDomainName = domainName.length <= 1
        ? domainName
        : '${domainName.substring(0, 1)}${'*' * (domainName.length - 1)}';

    return '$censoredLocal@$censoredDomainName$domainExtension';
  }

  Widget _buildKaomoji() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          _kaomoji,
          style: context.textTheme.displaySmall?.copyWith(
            color: context.colorScheme.secondary.withAlpha(80),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.padding),
        child: BlocSelector<ConfirmEmailCubit, ConfirmEmailState, bool>(
          selector: (state) => state is ConfirmEmailLoadingState,
          builder: (context, loading) {
            return ElevatedButton(
              onPressed: loading ? null : _cubit.sendVerificationEmail,
              child: Text(
                (loading
                        ? context.l10n.resendingEmailButton
                        : context.l10n.resendEmailButton)
                    .toUpperCase(),
              ),
            );
          },
        ),
      ),
    );
  }
}
