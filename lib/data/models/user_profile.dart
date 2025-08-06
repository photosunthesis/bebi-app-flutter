import 'package:bebi_app/constants/hive_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  @HiveType(typeId: HiveTypeIds.userProfile)
  const factory UserProfile({
    @HiveField(0) required String userId,
    @HiveField(1) required String code,
    @HiveField(2) required DateTime birthDate,
    @HiveField(3) required String displayName,
    @HiveField(4) String? photoUrl,
    @HiveField(5) required String createdBy,
    @HiveField(6) required DateTime createdAt,
    @HiveField(7) required DateTime updatedAt,
    @HiveField(8) @Default(false) bool didSetUpCycles,
    @HiveField(9) @Default(false) bool hasCycle,
    @HiveField(10) @Default(false) bool isSharingCycleWithPartner,
  }) = _UserProfile;

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      userId: doc.id,
      code: data['code'] as String,
      birthDate: (data['birth_date'] as Timestamp).toDate(),
      displayName: data['display_name'] as String,
      photoUrl: data['photo_url'] as String?,
      createdBy: data['created_by'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      didSetUpCycles: data['did_set_up_cycles'] as bool,
      hasCycle: data['has_cycle'] as bool,
      isSharingCycleWithPartner: data['is_sharing_cycle_with_partner'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // ID is managed by Firestore
      'code': code,
      'birth_date': Timestamp.fromDate(birthDate),
      'display_name': displayName,
      'photo_url': photoUrl,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'did_set_up_cycles': didSetUpCycles,
      'has_cycle': hasCycle,
      'is_sharing_cycle_with_partner': isSharingCycleWithPartner,
    };
  }
}
