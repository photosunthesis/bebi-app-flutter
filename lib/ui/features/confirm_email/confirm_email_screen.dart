import 'dart:math';

import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/kaomojis.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/confirm_email/confirm_email_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConfirmEmailScreen extends StatefulWidget {
  const ConfirmEmailScreen({super.key});

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  late final _cubit = context.read<ConfirmEmailCubit>();
  static final _kaomoji =
      Kaomojis.happySet[Random().nextInt(Kaomojis.happySet.length)];

  @override
  void initState() {
    super.initState();
    _cubit.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocListener<ConfirmEmailCubit, ConfirmEmailState>(
        listener: (context, state) => switch (state) {
          ConfirmEmailStateSuccess() => context.goNamed(AppRoutes.home),
          ConfirmEmailStateError(:final error) => context.showSnackbar(
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
            l10n.checkEmailTitle,
            style: context.primaryTextTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            child: BlocBuilder<ConfirmEmailCubit, ConfirmEmailState>(
              buildWhen: (p, c) =>
                  c is ConfirmEmailStateData || p is ConfirmEmailStateData,
              builder: (context, state) {
                final email = _censorEmail(switch (state) {
                  ConfirmEmailStateData(:final email) => email,
                  _ => '',
                });

                return RichText(
                  text: TextSpan(
                    style: context.textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                      fontWeight: FontWeight.normal,
                    ),
                    children: [
                      TextSpan(text: l10n.checkEmailMessagePrefix),
                      TextSpan(
                        text: email,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: l10n.checkEmailMessageSuffix),
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
          selector: (state) => state is ConfirmEmailStateLoading,
          builder: (context, loading) {
            return ElevatedButton(
              onPressed: loading ? null : _cubit.sendVerificationEmail,
              child: Text(
                (loading ? l10n.resendingEmailButton : l10n.resendEmailButton)
                    .toUpperCase(),
              ),
            );
          },
        ),
      ),
    );
  }
}
