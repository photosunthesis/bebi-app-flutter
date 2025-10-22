import 'package:bebi_app/data/models/user_profile.dart';

class UserProfileWithPictureDto extends UserProfile {
  const UserProfileWithPictureDto._({
    required super.userId,
    required super.code,
    required super.birthDate,
    required super.displayName,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.profilePictureStorageName,
    super.didSetUpCycles,
    super.hasCycle,
    super.isSharingCycleWithPartner,
    super.fcmTokens,
    this.profilePictureUrl,
  });

  factory UserProfileWithPictureDto.fromUserProfile(
    UserProfile userProfile,
    String? profilePictureUrl,
  ) {
    return UserProfileWithPictureDto._(
      userId: userProfile.userId,
      code: userProfile.code,
      birthDate: userProfile.birthDate,
      displayName: userProfile.displayName,
      createdBy: userProfile.createdBy,
      createdAt: userProfile.createdAt,
      updatedAt: userProfile.updatedAt,
      profilePictureStorageName: userProfile.profilePictureStorageName,
      didSetUpCycles: userProfile.didSetUpCycles,
      hasCycle: userProfile.hasCycle,
      isSharingCycleWithPartner: userProfile.isSharingCycleWithPartner,
      fcmTokens: userProfile.fcmTokens,
      profilePictureUrl: profilePictureUrl,
    );
  }

  final String? profilePictureUrl;

  @override
  List<Object?> get props => [...super.props, profilePictureUrl];
}
