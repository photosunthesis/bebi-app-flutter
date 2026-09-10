import 'package:bebi_app/features/account/domain/entities/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension UserProfileDto on UserProfile {
  static UserProfile fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      userId: doc.id,
      code: data['code'] as String,
      birthDate: (data['birth_date'] as Timestamp).toDate(),
      displayName: data['display_name'] as String,
      createdBy: data['created_by'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      profilePictureStorageName:
          data['profile_picture_storage_name'] as String?,
      didSetUpCycles: data['did_set_up_cycles'] as bool,
      hasCycle: data['has_cycle'] as bool,
      isSharingCycleWithPartner: data['is_sharing_cycle_with_partner'] as bool,
      fcmTokens: List<String>.from(data['fcm_tokens'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'birth_date': Timestamp.fromDate(birthDate),
      'display_name': displayName,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'profile_picture_storage_name': profilePictureStorageName,
      'did_set_up_cycles': didSetUpCycles,
      'has_cycle': hasCycle,
      'is_sharing_cycle_with_partner': isSharingCycleWithPartner,
      'fcm_tokens': fcmTokens,
    };
  }
}
