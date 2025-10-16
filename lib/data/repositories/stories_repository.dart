import 'package:bebi_app/data/models/story.dart';
import 'package:bebi_app/data/services/r2_objects_service.dart';
import 'package:blurhash_ffi/blurhash.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@injectable
class StoriesRepository {
  const StoriesRepository(
    this._firestore,
    this._r2ObjectsService,
    this._storiesBox,
  );

  final FirebaseFirestore _firestore;
  final R2ObjectsService _r2ObjectsService;
  final Box<Story> _storiesBox;

  static const _collection = 'stories';

  Future<List<Story>> getUserStories(
    String userId, {
    bool useCache = true,
  }) async {
    if (useCache && _storiesBox.isNotEmpty) {
      final cachedStories = _storiesBox.values.toList();
      if (cachedStories.isNotEmpty) return cachedStories;
    }

    final querySnapshot = await _firestore
        .collection(_collection)
        .where('users', arrayContains: userId)
        .orderBy('created_at', descending: true)
        .get();

    final stories = querySnapshot.docs.map(Story.fromFirestore).toList();

    await _storiesBox.clear();
    for (final story in stories) {
      await _storiesBox.put(story.id, story);
    }

    return stories;
  }

  Future<Story> createStory({
    required String createdBy,
    required String title,
    required List<String> users,
    required XFile imageFile,
  }) async {
    final blurHash = await BlurhashFFI.encode(
      XFileImage(imageFile),
      componentX: 2,
      componentY: 2,
    );

    final storageObjectName = await _r2ObjectsService.uploadFile(
      imageFile,
      path: _collection,
    );

    final story = Story(
      id: '', // Will be set after Firestore document creation
      storageObjectName: storageObjectName,
      blurHash: blurHash,
      createdBy: createdBy,
      title: title,
      users: users,
    );

    final docRef = await _firestore
        .collection(_collection)
        .add(story.toFirestore());

    final newStory = story.copyWith(id: docRef.id);
    await _storiesBox.put(newStory.id, newStory);

    return newStory;
  }

  Future<void> deleteStory(String storyId) async {
    await _firestore.collection(_collection).doc(storyId).delete();
    await _storiesBox.delete(storyId);
  }
}
