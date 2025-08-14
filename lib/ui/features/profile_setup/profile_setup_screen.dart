import 'dart:io';

import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/profile_setup/profile_setup_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/shadow/shadow_container.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/extension/string_extensions.dart';
import 'package:bebi_app/utils/formatter/date_input_formatter.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final _cubit = context.read<ProfileSetupCubit>();

  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _birthdayController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileSetupCubit, ProfileSetupState>(
      listener: (context, state) {
        if (state.success) context.goNamed(AppRoutes.home);
        if (state.error != null) context.showSnackbar(state.error!);
      },
      child: Form(
        canPop: false,
        key: _formKey,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: ListView(
            children: [
              const SafeArea(child: SizedBox(height: UiConstants.padding)),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildProfilePicture(),
              const SizedBox(height: 44),
              _buildDisplayNameField(),
              const SizedBox(height: 16),
              _buildBirthdateField(),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: BlocSelector<ProfileSetupCubit, ProfileSetupState, File?>(
        selector: (state) => state.profilePicture,
        builder: (context, profilePicture) {
          final hasProfilePicture = profilePicture != null;
          return Align(
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: 300.milliseconds,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colorScheme.outline,
                        width: UiConstants.borderWidth,
                      ),
                    ),
                    child: CircleAvatar(
                      key: ValueKey(profilePicture),
                      radius: 60,
                      backgroundColor: Colors.transparent,
                      backgroundImage: hasProfilePicture
                          ? FileImage(profilePicture)
                          : null,
                      child: !hasProfilePicture
                          ? Icon(
                              Symbols.face,
                              size: 50,
                              color: context.colorScheme.secondary.withAlpha(
                                100,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -5,
                  right: -18,
                  child: ShadowContainer(
                    shape: BoxShape.circle,
                    shadowOffset: const Offset(0, 0),
                    child: TextButton(
                      onPressed: hasProfilePicture
                          ? _cubit.removeProfilePicture
                          : _cubit.setProfilePicture,
                      style: IconButton.styleFrom(
                        backgroundColor: context.colorScheme.onPrimary,
                        foregroundColor: hasProfilePicture
                            ? context.colorScheme.error
                            : context.colorScheme.primary,
                        padding: const EdgeInsets.all(8),
                        shape: const CircleBorder(),
                      ),
                      child: Icon(
                        profilePicture != null
                            ? Symbols.delete
                            : Symbols.add_a_photo,

                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
            context.l10n.profileSetupTitle,
            style: context.primaryTextTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            child: Text(
              context.l10n.profileSetupSubtitle,
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

  Widget _buildDisplayNameField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: AppTextFormField(
        controller: _displayNameController,
        labelText: context.l10n.displayNameLabel,
        hintText: context.l10n.displayNameHint,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        autofillHints: const <String>[AutofillHints.nickname],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.l10n.displayNameRequired;
          }

          if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
            return context.l10n.displayNameInvalid;
          }

          if (value.length > 32) {
            return context.l10n.displayNameTooLong;
          }

          return null;
        },
      ),
    );
  }

  Widget _buildBirthdateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: AppTextFormField(
        controller: _birthdayController,
        labelText: context.l10n.birthdateLabel,
        hintText: context.l10n.birthdateHint,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.birthday],
        inputFormatters: const [DateInputFormatter()],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return context.l10n.birthdateRequired;
          }

          final date = value.toDateTime('MM/dd/yyyy');

          if (date == null) {
            return context.l10n.birthdateInvalid;
          }

          if (date.isAfter(DateTime.now())) {
            return context.l10n.birthdateFuture;
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
        child: BlocSelector<ProfileSetupCubit, ProfileSetupState, bool>(
          selector: (state) => state.loading,
          builder: (context, loading) {
            return ElevatedButton(
              onPressed: loading
                  ? null
                  : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _cubit.updateUserProfile(
                          _displayNameController.text,
                          _birthdayController.text.toDateTime('MM/dd/yyyy')!,
                        );
                      }
                    },

              child: Text(
                (loading
                        ? context.l10n.updatingProfileButton
                        : context.l10n.updateProfileButton)
                    .toUpperCase(),
              ),
            );
          },
        ),
      ),
    );
  }
}
