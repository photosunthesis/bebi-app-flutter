import 'dart:async';
import 'dart:math';

import 'package:bebi_app/data/models/async_value.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

part 'profile_setup_state.dart';

@injectable
class ProfileSetupCubit extends Cubit<ProfileSetupState>
    with GuardMixin, AnalyticsMixin, LocalizationsMixin {
  ProfileSetupCubit(
    this._userProfileRepository,
    this._firebaseAuth,
    this._imagePicker,
  ) : super(const ProfileSetupState()) {
    logScreenViewed(screenName: 'profile_setup_screen');
  }

  final UserProfileRepository _userProfileRepository;
  final FirebaseAuth _firebaseAuth;
  final ImagePicker _imagePicker;

  Future<void> initialize() async {
    await guard(
      () async {
        emit(state.copyWith(updateProfileAsync: const AsyncLoading()));

        final userProfile = await _userProfileRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        final profilePictureUrl = await _userProfileRepository
            .getUserProfilePictureUrl(userProfile!);

        emit(
          state.copyWith(
            photo: profilePictureUrl,
            displayName: userProfile.displayName,
            birthDate: userProfile.birthDate,
            userIsLoggedIn: _firebaseAuth.currentUser != null,
          ),
        );
      },
      onComplete: () {
        emit(state.copyWith(updateProfileAsync: const AsyncData(false)));
      },
    );
  }

  Future<void> setProfilePicture() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 600,
      maxHeight: 600,
      requestFullMetadata: false,
    );

    if (pickedFile != null) {
      emit(state.copyWith(photo: pickedFile.path, photoChanged: true));
      logUserAction(action: 'profile_picture_selected');
    }
  }

  void removeProfilePicture() {
    // ignore: avoid_redundant_argument_values
    emit(state.copyWith(photo: null, photoChanged: true));
    logUserAction(action: 'profile_picture_removed');
  }

  Future<void> updateUserProfile(String displayName, DateTime birthDate) async {
    await guard(
      () async {
        emit(state.copyWith(updateProfileAsync: const AsyncLoading()));

        final profilePictureStorageName = state.photo != null
            ? await _userProfileRepository.uploadProfilePictureFile(
                _firebaseAuth.currentUser!.uid,
                XFile(
                  state.photo!,
                  mimeType: 'image/jpeg',
                  name: 'profile_${_firebaseAuth.currentUser!.uid}.jpg',
                ),
              )
            : null;

        // Check if there's an existing profile picture and delete it before updating
        final userId = _firebaseAuth.currentUser!.uid;
        final existingUserProfile = await _userProfileRepository.getByUserId(
          userId,
        );

        if (existingUserProfile?.profilePictureStorageName != null &&
            existingUserProfile!.profilePictureStorageName!.isNotEmpty) {
          await _userProfileRepository.deleteUserProfilePicture(
            existingUserProfile,
          );
        }

        await Future.wait([
          _firebaseAuth.currentUser!.updateDisplayName(displayName),
          _userProfileRepository.createOrUpdate(
            UserProfile(
              userId: userId,
              createdBy: userId,
              code: await _generateUserCode(),
              birthDate: birthDate,
              displayName: displayName,
              profilePictureStorageName: profilePictureStorageName,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ]);

        emit(state.copyWith(updateProfileAsync: const AsyncData(true)));

        logUserAction(
          action: 'profile_setup_completed',
          parameters: {
            'has_profile_picture': profilePictureStorageName != null,
            'display_name_length': displayName.length,
            'age_years': DateTime.now().difference(birthDate).inDays ~/ 365,
          },
        );
      },
      onError: (error, stack) {
        emit(state.copyWith(updateProfileAsync: AsyncError(error, stack)));
      },
    );
  }

  Future<String> _generateUserCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();

    for (var attempts = 0; attempts < 100; attempts++) {
      final code = List.generate(
        6,
        (_) => chars[rand.nextInt(chars.length)],
      ).join();

      if (await _userProfileRepository.getByUserCode(code) == null) {
        return code;
      }
    }

    throw Exception('Failed to generate unique user code after 100 attempts');
  }
}
