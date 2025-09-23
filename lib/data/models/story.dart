import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Story extends Equatable {
  Story({
    required this.id,
    required this.title,
    required this.photoUrl,
    required this.createdBy,
    required this.users,
    required this.blurHash,
    required DateTime createdAt,
  }) : _createdAt = createdAt.toUtc();

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      id: doc.id,
      title: data['title'] as String,
      photoUrl: data['photoUrl'] as String,
      createdBy: data['createdBy'] as String,
      users: List<String>.from(data['users'] as List),
      blurHash: data['blurHash'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  final String id;
  final String title;
  final String photoUrl;
  final String createdBy;
  final List<String> users;
  final String blurHash;
  final DateTime _createdAt;

  DateTime get createdAt => _createdAt.toLocal();

  Map<String, dynamic> toFirestore() {
    return {
      // ID is handled by Firestore
      'title': title,
      'photoUrl': photoUrl,
      'createdBy': createdBy,
      'users': users,
      'blurHash': blurHash,
      'createdAt': _createdAt,
    };
  }

  Story copyWith({
    String? id,
    String? title,
    String? photoUrl,
    String? createdBy,
    List<String>? users,
    String? blurHash,
    DateTime? createdAt,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      photoUrl: photoUrl ?? this.photoUrl,
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
    photoUrl,
    createdBy,
    users,
    blurHash,
    _createdAt,
  ];
}
