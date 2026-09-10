import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bebi_app/core/data/image_storage_repository.dart';
import 'package:bebi_app/features/stories/data/story_dto.dart';
import 'package:bebi_app/features/stories/domain/entities/story.dart';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';

@injectable
class StoriesRepository {
  StoriesRepository(
    this._firestore,
    this._imageStorageRepository,
    this._storiesBox,
    @Named('story_image_url_box') this._storyImageUrlBox,
  );

  final FirebaseFirestore _firestore;
  final ImageStorageRepository _imageStorageRepository;
  final Box<Story> _storiesBox;
  final Box<String> _storyImageUrlBox;

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

    final stories = querySnapshot.docs.map(StoryDto.fromFirestore).toList();

    unawaited(
      _storiesBox.putAll({for (final story in stories) story.id: story}),
    );

    return stories;
  }

  Future<Story> createStory({
    required String createdBy,
    required String title,
    required List<String> users,
    required XFile imageFile,
  }) async {
    final blurHash = await _encodeBlurHash(imageFile);

    final objectName = await _imageStorageRepository.uploadStoryImageFile(
      imageFile,
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
    unawaited(_storiesBox.put(newStory.id, newStory));

    return newStory;
  }

  Future<void> deleteStory(Story story) async {
    await _imageStorageRepository.deleteImageByObjectName(
      story.storageObjectName,
    );
    await _firestore.collection(_collection).doc(story.id).delete();
    await _storiesBox.delete(story.id);
  }

  Future<String> getStoryImageUrl(Story story, {bool useCache = true}) async {
    if (useCache && _storyImageUrlBox.containsKey(story.storageObjectName)) {
      final cachedJson = _storyImageUrlBox.get(story.storageObjectName)!;
      final cached = jsonDecode(cachedJson) as Map<String, dynamic>;
      final fetchedAt = DateTime.parse(cached['fetchedAt'] as String);
      final age = DateTime.now().difference(fetchedAt);

      // Consider presigned URL valid for 6 days
      if (age.inDays < 6) return cached['imageUrl'] as String;
    }

    final storyImageUrl = await _imageStorageRepository.getImageUrlByObjectName(
      story.storageObjectName,
    );

    unawaited(
      _storyImageUrlBox.put(
        story.storageObjectName,
        jsonEncode({
          'imageUrl': storyImageUrl,
          'fetchedAt': DateTime.now().toIso8601String(),
        }),
      ),
    );

    return storyImageUrl;
  }

  // The hash only holds a few components, so a 64px decode is plenty and keeps
  // the pure Dart encode off the UI thread's critical path.
  Future<String> _encodeBlurHash(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);

    try {
      final frame = await codec.getNextFrame();

      try {
        final rgba = await frame.image.toByteData();

        final image = img.Image.fromBytes(
          width: frame.image.width,
          height: frame.image.height,
          bytes: rgba!.buffer,
          numChannels: 4,
        );

        return BlurHash.encode(image, numCompX: 3, numCompY: 2).hash;
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  Future<Uint8List> getStoryImageBytes(Story story) async {
    final imageUrl = await getStoryImageUrl(story);
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to download image.');
    }

    return response.bodyBytes;
  }
}
