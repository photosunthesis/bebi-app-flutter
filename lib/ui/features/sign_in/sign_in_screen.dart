import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/app_assets.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/sign_in/sign_in_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/shadow/shadow_container.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
      listener: (context, state) {
        if (state is SignInSuccess) {
          context.goNamed(AppRoutes.home);
        }

        if (state is SignInFailure) {
          context.showSnackbar(state.error);
        }
      },
      child: Form(
        key: _formKey,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UiConstants.defaultPadding,
            ),
            child: ListView(
              children: [
                const SizedBox(height: 20),
                _buildLogo(),
                const SizedBox(height: 28),
                _buildGreeting(),
                const SizedBox(height: 28),
                _buildFormFields(),
                const SizedBox(height: 16),
                _buildForgotPassword(),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigation(),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(AppAssets.mainLogo, height: 32),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hello again!', style: context.primaryTextTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account to continue.',
          style: context.textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return BlocSelector<SignInCubit, SignInState, bool>(
      selector: (state) => state is SignInLoading,
      builder: (context, loading) => Column(
        children: [
          AppTextFormField(
            enabled: !loading,
            controller: _emailController,
            labelText: 'Email',
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextFormField(
            enabled: !loading,
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Your secret password',
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return SizedBox(
      width: double.infinity,
      child: RichText(
        text: TextSpan(
          style: context.textTheme.bodyMedium,
          children: [
            const TextSpan(text: 'Forgot password? '),
            TextSpan(
              text: 'Tap here to reset.',
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // TODO Handle reset password tap
                  context.showSnackbar(
                    'Reset password feature is not implemented yet. 😅',
                  );
                },
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BlocSelector<SignInCubit, SignInState, bool>(
      selector: (state) => state is SignInLoading,
      builder: (context, loading) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadowContainer(
                child: ElevatedButton(
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
                  child: const Text('Sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
