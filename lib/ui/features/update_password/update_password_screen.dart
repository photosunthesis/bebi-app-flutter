import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/update_password/update_password_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/ui/shared_widgets/modals/options_bottom_dialog.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      canPop: false,
      onPopInvokedWithResult: _onPop,
      key: _formKey,
      child: BlocListener<UpdatePasswordCubit, UpdatePasswordState>(
        listener: (context, state) => switch (state) {
          UpdatePasswordSuccessState() => context.pop(),
          UpdatePasswordErrorState(:final error) => context.showSnackbar(
            error,
            type: SnackbarType.error,
          ),
          _ => null,
        },
        child: Scaffold(
          appBar: MainAppBar.build(context),
          body: ListView(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildOldPasswordField(),
              const SizedBox(height: 16),
              _buildNewPasswordField(),
              const SizedBox(height: 16),
              _buildConfirmPasswordField(),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  void _onPop(bool didPop, Object? _) {
    if (didPop) return;

    Future.microtask(() async {
      final shouldPop = await OptionsBottomDialog.show(
        context,
        title: context.l10n.leaveWithoutSavingPasswordTitle,
        description: context.l10n.leaveWithoutSavingPasswordMessage,
        options: [
          Option(
            text: context.l10n.continueEditingButton,
            value: false,
            style: OptionStyle.primary,
          ),
          Option(text: context.l10n.discardChangesButton, value: true),
        ],
      );
      if (shouldPop == true) context.pop();
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(UiConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.updatePasswordTitle,
            style: context.primaryTextTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            child: Text(
              context.l10n.updatePasswordSubtitle,
              style: context.textTheme.bodyLarge?.copyWith(
                height: 1.4,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOldPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: AppTextFormField(
        labelText: context.l10n.oldPasswordLabel,
        hintText: context.l10n.oldPasswordHint,
        controller: _oldPasswordController,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.next,
        obscureText: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.l10n.oldPasswordRequired;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildNewPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: AppTextFormField(
        labelText: context.l10n.newPasswordLabel,
        hintText: context.l10n.newPasswordHint,
        controller: _newPasswordController,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.next,
        obscureText: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.l10n.newPasswordRequired;
          }

          if (value.length < 8) {
            return context.l10n.passwordTooShort;
          }

          if (value == _oldPasswordController.text) {
            return context.l10n.passwordSameAsOld;
          }

          final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
          final hasNumber = RegExp(r'[0-9]').hasMatch(value);

          if (!hasLetter || !hasNumber) {
            return context.l10n.passwordMustContainLettersAndNumbers;
          }

          if (value != _confirmPasswordController.text) {
            return context.l10n.passwordsDoNotMatch;
          }

          return null;
        },
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: AppTextFormField(
        labelText: context.l10n.confirmNewPasswordLabel,
        hintText: context.l10n.confirmNewPasswordHint,
        controller: _confirmPasswordController,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.done,
        obscureText: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.l10n.confirmNewPasswordRequired;
          }

          if (value != _newPasswordController.text) {
            return context.l10n.passwordsDoNotMatch;
          }

          return null;
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.padding),
        child: BlocSelector<UpdatePasswordCubit, UpdatePasswordState, bool>(
          selector: (state) => state is UpdatePasswordLoadingState,
          builder: (context, loading) {
            return ElevatedButton(
              onPressed: loading
                  ? null
                  : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        context.read<UpdatePasswordCubit>().updatePassword(
                          oldPassword: _oldPasswordController.text,
                          newPassword: _newPasswordController.text,
                        );
                      }
                    },
              child: Text(
                (loading
                        ? context.l10n.updatingPasswordButton
                        : context.l10n.updatePasswordButton)
                    .toUpperCase(),
              ),
            );
          },
        ),
      ),
    );
  }
}
