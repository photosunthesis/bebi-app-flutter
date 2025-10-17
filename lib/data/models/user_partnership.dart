import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserPartnership extends Equatable {
  UserPartnership({
    required this.id,
    required this.users,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : _createdAt = (createdAt ?? DateTime.now()).toUtc(),
       _updatedAt = (updatedAt ?? DateTime.now()).toUtc();

  factory UserPartnership.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserPartnership(
      id: doc.id,
      users: (data['users'] as List<dynamic>).map((e) => e as String).toList(),
      createdBy: data['created_by'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  final String id;
  final List<String> users;
  final String createdBy;
  final DateTime _createdAt;
  final DateTime _updatedAt;

  DateTime get createdAt => _createdAt.toLocal();
  DateTime get updatedAt => _updatedAt.toLocal();

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
      createdAt: createdAt ?? _createdAt,
      updatedAt: updatedAt ?? _updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'users': users,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(_createdAt),
      'updated_at': Timestamp.fromDate(_updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, users, createdBy, _createdAt, _updatedAt];
}
