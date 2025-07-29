import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.code,
    required this.birthDate,
    required this.displayName,
    required this.photoUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
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

  UserProfile updated() {
    return copyWith(updatedAt: DateTime.now().toUtc());
  }

  UserProfile copyWith({
    String? userId,
    String? code,
    DateTime? birthDate,
    String? displayName,
    String? photoUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
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
    );
  }
}
