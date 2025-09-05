import 'dart:async';
import 'dart:math';

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
  ) : super(const ProfileSetupLoadedState()) {
    logScreenViewed(screenName: 'profile_setup_screen');
  }

  final UserProfileRepository _userProfileRepository;
  final FirebaseAuth _firebaseAuth;
  final ImagePicker _imagePicker;

  Future<void> initialize() async {
    await guard(() async {
      emit(const ProfileSetupLoadingState());

      final userProfile = await _userProfileRepository.getByUserId(
        _firebaseAuth.currentUser!.uid,
      );

      emit(
        ProfileSetupLoadedState(
          photo: userProfile?.photoUrl,
          displayName: userProfile?.displayName,
          birthDate: userProfile?.birthDate,
        ),
      );
    });
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
      emit(ProfileSetupLoadedState(photo: pickedFile.path));

      logUserAction(action: 'profile_picture_selected');
    }
  }

  void removeProfilePicture() {
    emit(const ProfileSetupLoadedState());
    logUserAction(action: 'profile_picture_removed');
  }

  Future<void> updateUserProfile(String displayName, DateTime birthDate) async {
    final photoFilePath = (state as ProfileSetupLoadedState).photo;

    await guard(
      () async {
        emit(const ProfileSetupLoadingState());

        final photoUrl = photoFilePath != null
            ? await _userProfileRepository.uploadProfileImage(
                _firebaseAuth.currentUser!.uid,
                XFile(photoFilePath),
              )
            : null;

        await Future.wait([
          _firebaseAuth.currentUser!.updateDisplayName(displayName),
          _firebaseAuth.currentUser!.updatePhotoURL(photoUrl),
          _userProfileRepository.createOrUpdate(
            UserProfile(
              userId: _firebaseAuth.currentUser!.uid,
              createdBy: _firebaseAuth.currentUser!.uid,
              code: await _generateUserCode(),
              birthDate: birthDate,
              displayName: displayName,
              photoUrl: photoUrl,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        ]);

        emit(const ProfileSetupSuccessState());

        logUserAction(
          action: 'profile_setup_completed',
          parameters: {
            'has_profile_picture': photoUrl != null,
            'display_name_length': displayName.length,
            'age_years': DateTime.now().difference(birthDate).inDays ~/ 365,
          },
        );
      },
      onError: (error, _) {
        emit(ProfileSetupErrorState(l10n.serverError));
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
