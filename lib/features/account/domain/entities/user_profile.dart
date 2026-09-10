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
