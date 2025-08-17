import 'package:bebi_app/constants/hive_type_ids.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'user_profile.g.dart';

@HiveType(typeId: HiveTypeIds.userProfile)
class UserProfile extends Equatable {
  const UserProfile({
    required this.userId,
    required this.code,
    required this.birthDate,
    required this.displayName,
    this.photoUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.didSetUpCycles = false,
    this.hasCycle = false,
    this.isSharingCycleWithPartner = false,
  });

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

  @HiveField(0)
  final String userId;
  @HiveField(1)
  final String code;
  @HiveField(2)
  final DateTime birthDate;
  @HiveField(3)
  final String displayName;
  @HiveField(4)
  final String? photoUrl;
  @HiveField(5)
  final String createdBy;
  @HiveField(6)
  final DateTime createdAt;
  @HiveField(7)
  final DateTime updatedAt;
  @HiveField(8)
  final bool didSetUpCycles;
  @HiveField(9)
  final bool hasCycle;
  @HiveField(10)
  final bool isSharingCycleWithPartner;

  UserProfile copyWith({
    String? userId,
    String? code,
    DateTime? birthDate,
    String? displayName,
    String? photoUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? didSetUpCycles,
    bool? hasCycle,
    bool? isSharingCycleWithPartner,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      code: code ?? this.code,
      birthDate: birthDate ?? this.birthDate,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      didSetUpCycles: didSetUpCycles ?? this.didSetUpCycles,
      hasCycle: hasCycle ?? this.hasCycle,
      isSharingCycleWithPartner:
          isSharingCycleWithPartner ?? this.isSharingCycleWithPartner,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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

  @override
  List<Object?> get props => [
    userId,
    code,
    birthDate,
    displayName,
    photoUrl,
    createdBy,
    createdAt,
    updatedAt,
    didSetUpCycles,
    hasCycle,
    isSharingCycleWithPartner,
  ];
}
