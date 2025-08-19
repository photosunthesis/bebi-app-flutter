import 'dart:io';

import 'package:bebi_app/app/router/app_router.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/profile_setup/profile_setup_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/forms/app_text_form_field.dart';
import 'package:bebi_app/ui/shared_widgets/layouts/main_app_bar.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/extensions/string_extensions.dart';
import 'package:bebi_app/utils/formatters/date_input_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cubit.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileSetupCubit, ProfileSetupState>(
      listener: (context, state) {
        if (state is ProfileSetupSuccessState) {
          context.goNamed(AppRoutes.home);
        }

        if (state is ProfileSetupErrorState) {
          context.showSnackbar(state.error, type: SnackbarType.error);
        }

        if (state is ProfileSetupLoadedState) {
          if (state.displayName != null) {
            _displayNameController.text = state.displayName!;
          }
          if (state.birthDate != null) {
            _birthdayController.text = state.birthDate!.toMMddyyyy();
          }
        }
      },
      builder: (context, state) {
        final isEditing =
            state is ProfileSetupLoadedState &&
            state.displayName != null &&
            state.birthDate != null;
        return Form(
          canPop: isEditing,
          key: _formKey,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: isEditing ? MainAppBar.build(context) : null,
            body: ListView(
              children: [
                isEditing
                    ? const SizedBox(height: UiConstants.padding)
                    : const SafeArea(
                        child: SizedBox(height: UiConstants.padding),
                      ),
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
        );
      },
    );
  }

  Widget _buildProfilePicture() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
        buildWhen: (previous, current) => current is ProfileSetupLoadedState,
        builder: (context, state) {
          final backgroundImage = switch (state) {
            ProfileSetupLoadedState(photo: final photo?, isPhotoUrl: false) =>
              FileImage(File(photo)),
            ProfileSetupLoadedState(photo: final photo?, isPhotoUrl: true) =>
              CachedNetworkImageProvider(photo),
            _ => null,
          };

          return Align(
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
                      key: ValueKey(state),
                      radius: 60,
                      backgroundColor: Colors.transparent,
                      backgroundImage: backgroundImage as ImageProvider?,
                      child:
                          state is ProfileSetupLoadedState &&
                              state.photo == null
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
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.colorScheme.shadow.withAlpha(10),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed:
                          state is ProfileSetupLoadedState &&
                              state.photo != null
                          ? _cubit.removeProfilePicture
                          : _cubit.setProfilePicture,
                      style: IconButton.styleFrom(
                        backgroundColor: context.colorScheme.onPrimary,
                        foregroundColor:
                            state is ProfileSetupLoadedState &&
                                state.photo != null
                            ? context.colorScheme.error
                            : context.colorScheme.primary,
                        padding: const EdgeInsets.all(8),
                        shape: const CircleBorder(),
                      ),
                      child: Icon(
                        state is ProfileSetupLoadedState && state.photo != null
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
          selector: (state) => state is ProfileSetupLoadingState,
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
