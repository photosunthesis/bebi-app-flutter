import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:bebi_app/utils/localizations_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

part 'profile_setup_state.dart';
part 'profile_setup_cubit.freezed.dart';

@injectable
class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit(
    this._userProfileRepository,
    this._firebaseAuth,
    this._imagePicker,
  ) : super(const ProfileSetupState());

  final UserProfileRepository _userProfileRepository;
  final FirebaseAuth _firebaseAuth;
  final ImagePicker _imagePicker;

  Future<void> setProfilePicture() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 600,
      maxHeight: 600,
      requestFullMetadata: false,
    );

    if (pickedFile != null) {
      emit(state.copyWith(profilePicture: File(pickedFile.path)));

      logEvent(
        name: 'profile_picture_selected',
        parameters: {
          'user_id': _firebaseAuth.currentUser!.uid,
          'image_source': 'gallery',
        },
      );
    }
  }

  void removeProfilePicture() {
    emit(state.copyWith(profilePicture: null));

    logEvent(
      name: 'profile_picture_removed',
      parameters: {'user_id': _firebaseAuth.currentUser!.uid},
    );
  }

  Future<void> updateUserProfile(String displayName, DateTime birthDate) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));

        final photoUrl = state.profilePicture == null
            ? null
            : await _userProfileRepository.uploadProfileImage(
                _firebaseAuth.currentUser!.uid,
                state.profilePicture!,
              );

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

        emit(state.copyWith(success: true));

        logEvent(
          name: 'profile_setup_completed',
          parameters: {
            'user_id': _firebaseAuth.currentUser!.uid,
            'has_profile_picture': photoUrl != null,
            'display_name_length': displayName.length,
            'age_years': DateTime.now().difference(birthDate).inDays ~/ 365,
          },
        );
      },
      onError: (error, _) {
        emit(state.copyWith(error: l10n.serverError));
      },
      onComplete: () {
        emit(state.copyWith(loading: false, error: null));
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
