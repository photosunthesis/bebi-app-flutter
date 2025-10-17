import 'package:bebi_app/data/models/story.dart';
import 'package:blurhash_ffi/blurhash.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

@injectable
class StoriesRepository {
  const StoriesRepository(this._firestore, this._functions, this._storiesBox);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
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
      componentX: 3,
      componentY: 2,
    );

    final (uploadUrl, objectName) = await _functions
        .httpsCallable('getStoryUploadUrl')
        .call({'fileName': imageFile.name, 'contentType': imageFile.mimeType})
        .then((result) {
          final data = result.data as Map<String, dynamic>;
          return (data['uploadUrl'] as String, data['key'] as String);
        });

    await http.put(
      Uri.parse(uploadUrl),
      body: await imageFile.readAsBytes(),
      headers: {
        'Content-Type': imageFile.mimeType ?? 'application/octet-stream',
      },
    );

    final story = Story(
      id: '', // Will be set after Firestore document creation
      storageObjectName: objectName,
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

  Future<String> getStoryImageUrl(Story story) async {
    final result = await _functions.httpsCallable('getPresignedUrl').call({
      'filename': story.storageObjectName,
    });

    final data = result.data as Map<String, dynamic>;
    return data['url'] as String;
  }
}
