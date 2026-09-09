import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserPartnership extends Equatable {
  const UserPartnership({
    required this.id,
    required this.users,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPartnership.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserPartnership(
      id: doc.id,
      users: (data['users'] as List<dynamic>).map((e) => e as String).toList(),
      createdBy: data['created_by'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate().toUtc(),
      updatedAt: (data['updated_at'] as Timestamp).toDate().toUtc(),
    );
  }

  final String id;
  final List<String> users;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPartnership copyWith({
    String? id,
    List<String>? users,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPartnership(
      id: id ?? this.id,
      users: users ?? this.users,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'users': users,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt.toUtc()),
      'updated_at': Timestamp.fromDate(updatedAt.toUtc()),
    };
  }

  @override
  List<Object?> get props => [id, users, createdBy, createdAt, updatedAt];
}
