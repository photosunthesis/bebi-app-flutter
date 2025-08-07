import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/app_assets.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/sign_in/sign_in_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
        SignInFailure(:final String error) => context.showSnackbar(error),
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
            'Welcome back!',
            style: context.primaryTextTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
          child: Text(
            'Sign in to continue sharing experiences and moments with your partner.',
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
              labelText: 'Email',
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
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
              labelText: 'Password',
              hintText: 'Your secret password',
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const <String>[AutofillHints.password],
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
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
                  (loading ? 'Signing in...' : 'Sign in').toUpperCase(),
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
            const TextSpan(text: 'Forgot password? '),
            TextSpan(
              text: 'Tap here to reset.',
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO Handle reset password
                  context.showSnackbar(
                    'Reset password feature is not implemented yet.',
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
