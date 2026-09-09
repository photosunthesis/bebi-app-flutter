import 'package:equatable/equatable.dart';

class Story extends Equatable {
  Story({
    required this.id,
    required this.title,
    required this.storageObjectName,
    required this.createdBy,
    required this.users,
    required this.blurHash,
    DateTime? createdAt,
  }) : _createdAt = (createdAt ?? DateTime.now()).toUtc();

  final String id;
  final String title;
  final String storageObjectName;
  final String createdBy;
  final List<String> users;
  final String blurHash;
  final DateTime _createdAt;

  DateTime get createdAt => _createdAt.toLocal();

  Story copyWith({
    String? id,
    String? title,
    String? storageObjectName,
    String? createdBy,
    List<String>? users,
    String? blurHash,
    DateTime? createdAt,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      storageObjectName: storageObjectName ?? this.storageObjectName,
      createdBy: createdBy ?? this.createdBy,
      users: users ?? this.users,
      blurHash: blurHash ?? this.blurHash,
      createdAt: createdAt ?? _createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    storageObjectName,
    createdBy,
    users,
    blurHash,
    _createdAt,
  ];
}
