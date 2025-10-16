import 'package:bebi_app/data/services/r2_objects_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';

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

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      title: data['title'] as String,
      storageObjectName: data['storage_object_name'] as String,
      createdBy: data['created_by'] as String,
      users: List<String>.from(data['users'] as List),
      blurHash: data['blur_hash'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  final String id;
  final String title;
  final String storageObjectName;
  final String createdBy;
  final List<String> users;
  final String blurHash;
  final DateTime _createdAt;

  DateTime get createdAt => _createdAt.toLocal();

  Future<String> getPhotoUrl() async =>
      GetIt.I<R2ObjectsService>().getPresignedUrl(storageObjectName);

  Map<String, dynamic> toFirestore() {
    return {
      // ID is handled by Firestore
      'title': title,
      'storage_object_name': storageObjectName,
      'created_by': createdBy,
      'users': users,
      'blur_hash': blurHash,
      'created_at': _createdAt,
    };
  }

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
