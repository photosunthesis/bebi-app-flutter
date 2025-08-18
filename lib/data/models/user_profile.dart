import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

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

  final String userId;
  final String code;
  final DateTime birthDate;
  final String displayName;
  final String? photoUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool didSetUpCycles;
  final bool hasCycle;
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
