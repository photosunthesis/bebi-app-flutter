import 'package:bebi_app/features/account/data/user_partnerships_repository.dart';
import 'package:bebi_app/features/account/data/user_profile_repository.dart';
import 'package:bebi_app/features/account/domain/entities/couple_context.dart';
import 'package:bebi_app/features/account/domain/entities/user_profile.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

@injectable
class ResolveCoupleContextUsecase {
  const ResolveCoupleContextUsecase(
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  );

  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;

  /// Both members without their profile pictures. Nothing here costs a storage
  /// call, so this is the one to use when no avatar is on screen.
  Future<CoupleContext?> call({bool useCache = true}) =>
      _resolve(useCache: useCache, withProfilePictures: false);

  /// Both members plus their profile picture URLs. One storage call per member.
  Future<CoupleContext?> withProfilePictures({bool useCache = true}) =>
      _resolve(useCache: useCache, withProfilePictures: true);

  Future<CoupleContext?> _resolve({
    required bool useCache,
    required bool withProfilePictures,
  }) async {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    if (currentUserId == null) return null;

    final userProfile = await _userProfileRepository.getByUserId(
      currentUserId,
      useCache: useCache,
    );

    if (userProfile == null) return null;

    final me = await _toMember(userProfile, withProfilePictures);

    // A partner-side failure must not take the user's own identity with it, so
    // everything past this point falls back to a context with no partner.
    try {
      final partnership = await _userPartnershipsRepository.getByUserId(
        currentUserId,
        useCache: useCache,
      );

      final partnerId = partnership?.users.firstWhereOrNull(
        (userId) => userId != currentUserId,
      );

      if (partnerId == null) return CoupleContext(me: me);

      final partnerProfile = await _userProfileRepository.getByUserId(
        partnerId,
        useCache: useCache,
      );

      if (partnerProfile == null) return CoupleContext(me: me);

      return CoupleContext(
        me: me,
        partner: await _toMember(partnerProfile, withProfilePictures),
      );
    } catch (_) {
      return CoupleContext(me: me);
    }
  }

  Future<CoupleMember> _toMember(
    UserProfile userProfile,
    bool withProfilePicture,
  ) async {
    return CoupleMember(
      userId: userProfile.userId,
      displayName: userProfile.displayName,
      profilePictureUrl: withProfilePicture
          ? await _userProfileRepository.getUserProfilePictureUrl(userProfile)
          : null,
      hasCycle: userProfile.hasCycle,
      isSharingCycleWithPartner: userProfile.isSharingCycleWithPartner,
    );
  }
}
