import 'package:cloud_firestore/cloud_firestore.dart';

class Partnership {
  const Partnership({
    required this.id,
    required this.code,
    required this.createdAt,
    required this.updatedAt,
    required this.users,
  });

  factory Partnership.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Partnership(
      id: doc.id,
      code: data['code'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      users: (data['users'] as List<dynamic>)
          .map((user) => PartnershipUser.fromMap(user as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String code;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PartnershipUser> users;

  Map<String, dynamic> toFirestore() {
    return {
      // ID is managed by Firestore
      'code': code,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'users': users.map((user) => user.toMap()).toList(),
    };
  }

  Partnership copyWith({
    String? id,
    String? code,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PartnershipUser>? users,
  }) {
    return Partnership(
      id: id ?? this.id,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      users: users ?? this.users,
    );
  }
}

class PartnershipUser {
  const PartnershipUser({
    required this.id,
    required this.displayName,
    required this.photoUrl,
  });

  factory PartnershipUser.fromMap(Map<String, dynamic> map) {
    return PartnershipUser(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      photoUrl: map['photo_url'] as String?,
    );
  }

  final String id;
  final String displayName;
  final String? photoUrl;

  Map<String, dynamic> toMap() {
    return {'id': id, 'display_name': displayName, 'photo_url': photoUrl};
  }
}
