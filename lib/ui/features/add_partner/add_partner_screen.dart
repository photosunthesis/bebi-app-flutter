import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/add_partner/add_partner_event.dart';
import 'package:bebi_app/ui/features/add_partner/add_partner_state.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/formatters/user_code_formatter.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility_temp_fork/flutter_keyboard_visibility_temp_fork.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddPartnerScreen extends HookConsumerWidget
    with AddPartnerEvent, AddPartnerState, AnalyticsMixin {
  AddPartnerScreen({super.key});

  Future<void> _handleSubmit(
    GlobalKey<FormState> formKey,
    WidgetRef ref,
    BuildContext context,
  ) async {
    if (formKey.currentState?.validate() ?? false) {
      await connectWithPartner(ref)
          .then((_) {
            context.goNamed(AppRoutes.home);
          })
          .catchError((error) {
            context.showSnackbar(switch (error) {
              ArgumentError(:final message) =>
                message ?? context.l10n.unexpectedError,
              _ => context.l10n.unexpectedError,
            });
          });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = useState(false);
    final userCode = useState('');
    final userCodeController = useTextEditingController();
    final partnerCodeController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());

    useEffect(() {
      fetchUserCode(ref).then((code) {
        userCode.value = code;
        userCodeController.text = code;
      });
      return null;
    }, const []);

    return Form(
      key: formKey,
      canPop: false,
      child: KeyboardDismissOnTap(
        dismissOnCapturedTaps: true,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SafeArea(
                      child: SizedBox(height: UiConstants.padding),
                    ),
                    _buildHeader(context),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildCodeSections(
                  context,
                  userCodeController,
                  partnerCodeController,
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(
            context,
            handleSubmit: () => _handleSubmit(formKey, ref, context),
            loading: loading.value,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.addPartnerTitle,
            style: context.primaryTextTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.addPartnerSubtitle,
            style: context.textTheme.bodyLarge?.copyWith(
              height: 1.4,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCodeSection(
    BuildContext context,
    TextEditingController userCodeController,
  ) {
    return _buildCodeContainer(
      context,
      title: context.l10n.shareCodeTitle,
      child: Stack(
        children: [
          AppTextFormField(
            controller: userCodeController,
            hintText: context.l10n.codeHint,
            readOnly: true,
          ),
          Positioned(
            right: 4,
            top: 6,
            child: TextButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () async => _onShare(context, userCodeController),
              child: Text(context.l10n.copyButton.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onShare(
    BuildContext context,
    TextEditingController userCodeController,
  ) async {
    if (userCodeController.text.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: userCodeController.text.replaceAll('-', '')),
    );

    context.showSnackbar(
      context.l10n.codeCopied(userCodeController.text),
      type: SnackbarType.secondary,
    );

    logShare(
      method: 'copy',
      contentType: 'user_code',
      itemId: userCodeController.text.replaceAll('-', ''),
    );
  }

  Widget _buildPartnerCodeSection(
    BuildContext context,
    TextEditingController partnerCodeController,
  ) {
    return _buildCodeContainer(
      context,
      title: context.l10n.enterCodeTitle,
      child: AppTextFormField(
        controller: partnerCodeController,
        hintText: context.l10n.codeHint,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        inputFormatters: const [UserCodeFormatter()],
        autofillHints: const [AutofillHints.oneTimeCode],
        validator: (value) {
          if (value == null || value.isEmpty) return null;
          if (value.length != 7) return context.l10n.codeLength;
          return null;
        },
      ),
    );
  }

  Widget _buildCodeSections(
    BuildContext context,
    TextEditingController userCodeController,
    TextEditingController partnerCodeController,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildUserCodeSection(context, userCodeController),
          Text(
            context.l10n.orText,
            style: context.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _buildPartnerCodeSection(context, partnerCodeController),
          SizedBox(height: context.screenHeight * 0.12),
        ],
      ),
    );
  }

  Widget _buildCodeContainer(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(title, style: context.textTheme.bodyMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context, {
    required Function() handleSubmit,
    required bool loading,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.padding),
        child: ElevatedButton(
          onPressed: loading ? null : handleSubmit,
          child: Text(
            (loading
                    ? context.l10n.connectingButton
                    : context.l10n.finishConnectingButton)
                .toUpperCase(),
          ),
        ),
      ),
    );
  }
}
