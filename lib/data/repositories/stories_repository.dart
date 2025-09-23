import 'package:bebi_app/data/models/story.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@injectable
class StoriesRepository {
  const StoriesRepository(this._firestore, this._storiesBox);

  final FirebaseFirestore _firestore;
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
        .get();

    final stories = querySnapshot.docs.map(Story.fromFirestore).toList();

    await _storiesBox.clear();
    for (final story in stories) {
      await _storiesBox.put(story.id, story);
    }

    return stories;
  }

  Future<Story> createStory(Story story) async {
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
