import 'package:bebi_app/features/account/data/user_partnerships_repository.dart';
import 'package:bebi_app/features/account/data/user_profile_repository.dart';
import 'package:bebi_app/features/account/domain/entities/sharing_audience.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

@injectable
class ResolveSharingAudienceUsecase {
  const ResolveSharingAudienceUsecase(
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  );

  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;

  /// A cycle log. Visible to the partner when logging on their behalf or when
  /// cycle sharing is on, and owned by whoever the log is about.
  Future<SharingAudience> forLog({required bool logForPartner}) async {
    final currentUserId = _firebaseAuth.currentUser!.uid;

    final userProfile = await _userProfileRepository.getByUserId(currentUserId);
    final partnership = await _userPartnershipsRepository.getByUserId(
      currentUserId,
    );

    final partnerId = partnership!.users.firstWhere(
      (user) => user != currentUserId,
    );

    final isSharingCycleWithPartner = userProfile!.isSharingCycleWithPartner;

    return SharingAudience(
      users: logForPartner || isSharingCycleWithPartner
          ? partnership.users
          : [currentUserId],
      ownedBy: logForPartner ? partnerId : currentUserId,
      isSharingCycleWithPartner: isSharingCycleWithPartner,
    );
  }

  /// Cycle setup, where the sharing choice comes from the form rather than the
  /// stored profile because it is being written in the same operation.
  Future<SharingAudience> forSelf({required bool shareWithPartner}) async {
    final currentUserId = _firebaseAuth.currentUser!.uid;

    final partnership = await _userPartnershipsRepository.getByUserId(
      currentUserId,
    );

    return SharingAudience(
      users: shareWithPartner ? partnership!.users : [currentUserId],
      ownedBy: currentUserId,
      isSharingCycleWithPartner: shareWithPartner,
    );
  }

  /// Anything that is always visible to both partners, like calendar events and
  /// stories.
  Future<SharingAudience> shared() async {
    final currentUserId = _firebaseAuth.currentUser!.uid;

    final partnership = await _userPartnershipsRepository.getByUserId(
      currentUserId,
    );

    return SharingAudience(users: partnership!.users, ownedBy: currentUserId);
  }
}
