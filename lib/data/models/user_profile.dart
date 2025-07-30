import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String userId,
    required String code,
    required DateTime birthDate,
    required String displayName,
    required String? photoUrl,
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
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
    };
  }
}
