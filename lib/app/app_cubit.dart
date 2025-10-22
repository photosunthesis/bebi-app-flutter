import 'package:bebi_app/data/models/async_value.dart';
import 'package:bebi_app/data/models/user_profile_view.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'app_state.dart';

/// {@template app_cubit}
///
/// Cubit responsible for managing the global app state.
///
/// This includes loading and storing user profiles and partnership information.
/// Other global stuff can be added here as needed.
///
/// {@endtemplate}
@injectable
class AppCubit extends Cubit<AppState> with LocalizationsMixin {
  /// {@macro app_cubit}
  AppCubit(
    this._firebaseAuth,
    this._userProfileRepository,
    this._userPartnershipsRepository,
  ) : super(const AppState());

  final FirebaseAuth _firebaseAuth;
  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;

  Future<void> loadUserProfiles({bool useCache = true}) async {
    emit(
      state.copyWith(
        userProfileAsync: const AsyncLoading(),
        partnerProfileAsync: const AsyncLoading(),
      ),
    );

    final currentUserId = _firebaseAuth.currentUser?.uid;

    emit(
      state.copyWith(
        userProfileAsync: await AsyncValue.guard(() async {
          if (currentUserId == null) return null;

          final userProfile = await _userProfileRepository.getByUserId(
            currentUserId,
            useCache: useCache,
          );

          if (userProfile == null) return null;

          final profilePictureUrl = await _userProfileRepository
              .getUserProfilePictureUrl(userProfile);

          return UserProfileView.fromUserProfile(
            userProfile,
            profilePictureUrl,
          );
        }),
      ),
    );

    emit(
      state.copyWith(
        partnerProfileAsync: await AsyncValue.guard(() async {
          if (currentUserId == null) return null;

          final partnership = await _userPartnershipsRepository.getByUserId(
            currentUserId,
            useCache: useCache,
          );

          if (partnership == null) return null;

          final partnerProfile = await _userProfileRepository.getByUserId(
            partnership.users.firstWhere(
              (id) => id != _firebaseAuth.currentUser!.uid,
            ),
            useCache: useCache,
          );

          if (partnerProfile == null) return null;

          final partnerProfilePictureUrl = await _userProfileRepository
              .getUserProfilePictureUrl(partnerProfile);

          return UserProfileView.fromUserProfile(
            partnerProfile,
            partnerProfilePictureUrl,
          );
        }),
      ),
    );
  }

  void onUserSignInStatusChanged(bool isSignedIn) {
    emit(state.copyWith(userIsSignedIn: isSignedIn));
  }
}
