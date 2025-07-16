import 'dart:io';

import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/profile_setup/profile_setup_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/shadow/shadow_container.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extension/build_context_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
import 'package:bebi_app/utils/extension/text_style_extensions.dart';
import 'package:bebi_app/utils/formatter/birth_date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
        key: _formKey,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UiConstants.defaultPadding,
            ),
            child: ListView(
              children: [
                const SafeArea(child: SizedBox(height: 10)),
                Text(
                  'Set up your profile',
                  // textAlign: TextAlign.center,
                  style: context.primaryTextTheme.headlineSmall?.copyWith(
                    // fontWeight: FontWeight.w600,
                    // letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 30),
                _buildProfilePicture(),
                const SizedBox(height: 30),
                _buildDisplayNameField(),
                const SizedBox(height: 16),
                _buildBirthdayField(),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return BlocSelector<ProfileSetupCubit, ProfileSetupState, File?>(
      selector: (state) => state.profilePicture,
      builder: (context, profilePicture) {
        final hasProfilePicture = profilePicture != null;
        return Align(
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ShadowContainer(
                shape: BoxShape.circle,
                child: AnimatedSwitcher(
                  duration: 300.milliseconds,
                  child: CircleAvatar(
                    key: ValueKey(profilePicture?.path ?? 'no-image'),
                    radius: 60,
                    backgroundColor: context.colorScheme.secondary.withAlpha(
                      30,
                    ),
                    backgroundImage: hasProfilePicture
                        ? FileImage(profilePicture)
                        : null,
                    child: !hasProfilePicture
                        ? Icon(
                            Symbols.face,
                            size: 69,
                            color: context.colorScheme.primary.withAlpha(90),
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
                  offset: const Offset(0, 0),
                  child: TextButton(
                    onPressed: hasProfilePicture
                        ? _cubit.removeProfilePicture
                        : _cubit.setProfilePicture,
                    style: IconButton.styleFrom(
                      backgroundColor: hasProfilePicture
                          ? context.colorScheme.onPrimary
                          : context.colorScheme.primary,
                      foregroundColor: hasProfilePicture
                          ? context.colorScheme.error
                          : context.colorScheme.onPrimary,
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
    );
  }

  Widget _buildDisplayNameField() {
    return AppTextFormField(
      controller: _displayNameController,
      labelText: 'Display name',
      hintText: 'Your nickname',
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.nickname],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your preferred name.';
        }

        if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
          return 'Only letters, numbers, and spaces are allowed.';
        }

        if (value.length > 32) {
          return 'Name can\'t be longer than 32 characters.';
        }

        return null;
      },
    );
  }

  Widget _buildBirthdayField() {
    return AppTextFormField(
      controller: _birthdayController,
      labelText: 'Birthdate',
      hintText: 'DD/MM/YYYY',
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.birthday],
      inputFormatters: [BirthDateFormatter()],
      inputStyle: context.textTheme.bodyMedium?.monospace,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your birthdate.';
        }

        final date = DateFormat('dd/MM/yyyy').tryParseStrict(value);

        if (date == null) {
          return 'Please enter a valid date in DD/MM/YYYY format.';
        }

        if (date.isAfter(DateTime.now())) {
          return 'Birthdate cannot be in the future.';
        }

        return null;
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.defaultPadding),
        child: BlocSelector<ProfileSetupCubit, ProfileSetupState, bool>(
          selector: (state) => state.loading,
          builder: (context, loading) {
            return ShadowContainer(
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _cubit.updateUserProfile(
                            _displayNameController.text,
                            _birthdayController.text,
                          );
                        }
                      },

                child: Text('Save'.toUpperCase()),
              ),
            );
          },
        ),
      ),
    );
  }
}
