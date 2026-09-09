import 'package:equatable/equatable.dart';

class UserPartnership extends Equatable {
  const UserPartnership({
    required this.id,
    required this.users,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

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

  @override
  List<Object?> get props => [id, users, createdBy, createdAt, updatedAt];
}
