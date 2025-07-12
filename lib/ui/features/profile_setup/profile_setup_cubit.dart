import 'dart:io';

import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

part 'profile_setup_state.dart';

class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit(
    this._userProfileRepository,
    this._firebaseAuth,
    this._imagePicker,
  ) : super(const ProfileSetupState());

  final UserProfileRepository _userProfileRepository;
  final FirebaseAuth _firebaseAuth;
  final ImagePicker _imagePicker;

  Future<void> setProfilePicture(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
      maxWidth: 600,
      maxHeight: 600,
      requestFullMetadata: false,
    );

    if (pickedFile != null) {
      emit(state.copyWith(profilePicture: File(pickedFile.path)));
    }
  }

  Future<void> updateUserProfile(String displayName, String birthDate) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));

        final photoUrl = state.profilePicture == null
            ? null
            : await _userProfileRepository.uploadProfileImage(
                _firebaseAuth.currentUser!.uid,
                state.profilePicture!,
              );

        await _userProfileRepository.createOrUpdate(
          UserProfile(
            userId: _firebaseAuth.currentUser!.uid,
            birthDate: DateFormat('mm/dd/yyyy').parse(birthDate),
            createdAt: DateTime.now(),
            displayName: displayName,
            photoUrl: photoUrl,
            updatedAt: DateTime.now(),
          ),
        );

        emit(state.copyWith(success: true));
      },
      onError: (_, _) {
        emit(
          state.copyWith(
            error:
                'There was an issue with the server. Please try again later.',
          ),
        );
      },
      onComplete: () {
        emit(state.copyWith(loading: false));
      },
    );
  }
}
