import 'package:bebi_app/features/stories/domain/entities/story.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension StoryDto on Story {
  static Story fromFirestore(DocumentSnapshot doc) {
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

  Map<String, dynamic> toFirestore() {
    return {
      // ID is handled by Firestore
      'title': title,
      'storage_object_name': storageObjectName,
      'created_by': createdBy,
      'users': users,
      'blur_hash': blurHash,
      'created_at': createdAt,
    };
  }
}
