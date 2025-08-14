import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/app_assets.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/sign_in/sign_in_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInCubit, SignInState>(
      listener: (context, state) => switch (state) {
        SignInSuccess() => context.goNamed(AppRoutes.home),
        SignInFailure(:final error) => context.showSnackbar(error),
        _ => null,
      },
      child: Form(
        key: _formKey,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: ListView(
            children: [
              const SafeArea(child: SizedBox(height: UiConstants.padding)),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildFormFields(),
            ],
          ),
          bottomNavigationBar: _bottomBar(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            width: 42,
            height: 42,
            child: Image.asset(AppAssets.appLogo),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
          child: Text(
            context.l10n.signInWelcomeTitle,
            style: context.primaryTextTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
          child: Text(
            context.l10n.signInWelcomeSubtitle,
            style: context.textTheme.bodyLarge?.copyWith(
              height: 1.4,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return BlocSelector<SignInCubit, SignInState, bool>(
      selector: (state) => state is SignInLoading,
      builder: (context, loading) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UiConstants.padding,
            ),
            child: AppTextFormField(
              enabled: !loading,
              controller: _emailController,
              labelText: context.l10n.emailLabel,
              hintText: context.l10n.emailHint,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.emailRequired;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UiConstants.padding,
            ),
            child: AppTextFormField(
              enabled: !loading,
              controller: _passwordController,
              labelText: context.l10n.passwordLabel,
              hintText: context.l10n.passwordHint,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const <String>[AutofillHints.password],
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.passwordRequired;
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return BlocSelector<SignInCubit, SignInState, bool>(
      selector: (state) => state is SignInLoading,
      builder: (context, loading) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(UiConstants.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildForgotPassword(),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          context
                              .read<SignInCubit>()
                              .signInWithEmailAndPassword(
                                _emailController.text,
                                _passwordController.text,
                              );
                        }
                      },
                child: Text(
                  (loading
                          ? context.l10n.signingInButton
                          : context.l10n.signInButton)
                      .toUpperCase(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return SizedBox(
      width: double.infinity,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: context.textTheme.bodySmall,
          children: [
            TextSpan(text: context.l10n.forgotPasswordText),
            TextSpan(
              text: context.l10n.forgotPasswordLink,
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO Handle reset password
                  context.showSnackbar(
                    context.l10n.resetPasswordNotImplemented,
                  );
                },
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
