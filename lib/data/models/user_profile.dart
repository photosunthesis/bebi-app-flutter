import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.userId,
    required this.code,
    required this.birthDate,
    required this.displayName,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.profilePictureStorageName,
    this.didSetUpCycles = false,
    this.hasCycle = false,
    this.isSharingCycleWithPartner = false,
    this.fcmTokens = const [],
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
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

  final String userId;
  final String code;
  final DateTime birthDate;
  final String displayName;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePictureStorageName;
  final bool didSetUpCycles;
  final bool hasCycle;
  final bool isSharingCycleWithPartner;
  final List<String> fcmTokens;

  UserProfile copyWith({
    String? userId,
    String? code,
    DateTime? birthDate,
    String? displayName,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePictureStorageName,
    bool? didSetUpCycles,
    bool? hasCycle,
    bool? isSharingCycleWithPartner,
    List<String>? fcmTokens,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      code: code ?? this.code,
      birthDate: birthDate ?? this.birthDate,
      displayName: displayName ?? this.displayName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePictureStorageName:
          profilePictureStorageName ?? this.profilePictureStorageName,
      didSetUpCycles: didSetUpCycles ?? this.didSetUpCycles,
      hasCycle: hasCycle ?? this.hasCycle,
      isSharingCycleWithPartner:
          isSharingCycleWithPartner ?? this.isSharingCycleWithPartner,
      fcmTokens: fcmTokens ?? this.fcmTokens,
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

  @override
  List<Object?> get props => [
    userId,
    code,
    birthDate,
    displayName,
    createdBy,
    createdAt,
    updatedAt,
    profilePictureStorageName,
    didSetUpCycles,
    hasCycle,
    isSharingCycleWithPartner,
    fcmTokens,
  ];
}
