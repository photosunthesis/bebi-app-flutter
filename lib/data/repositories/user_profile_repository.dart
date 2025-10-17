import 'dart:async';
import 'package:bebi_app/config/firebase_providers.dart';
import 'package:bebi_app/config/hive_providers.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final userProfileRepositoryProvider = Provider.autoDispose(
  (ref) => UserProfileRepository(
    ref.read(firebaseFirestoreProvider),
    ref.read(userProfileBoxProvider),
  ),
);

class UserProfileRepository {
  const UserProfileRepository(this._firestore, this._userProfileBox);

  final FirebaseFirestore _firestore;
  final Box<UserProfile> _userProfileBox;

  static const _collection = 'user_profiles';

  Future<UserProfile?> getByUserId(
    String userId, {
    bool useCache = true,
  }) async {
    if (useCache && _userProfileBox.containsKey(userId)) {
      return _userProfileBox.get(userId);
    }

    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (!doc.exists) return null;

    final userProfile = UserProfile.fromFirestore(doc);

    await _cacheUserProfile(userProfile);

    return userProfile;
  }

  Future<List<UserProfile>> getProfilesByIds(List<String> userIds) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where(FieldPath.documentId, whereIn: userIds)
        .get();

    return querySnapshot.docs.map(UserProfile.fromFirestore).toList();
  }

  Future<UserProfile?> getByUserCode(
    String code, {
    bool useCache = true,
  }) async {
    if (useCache) {
      final cachedProfile = _getCachedProfileByCode(code);
      if (cachedProfile != null) return cachedProfile;
    }

    final querySnapshot = await _firestore
        .collection(_collection)
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    final userProfile = UserProfile.fromFirestore(querySnapshot.docs.first);

    unawaited(_cacheUserProfile(userProfile));

    return userProfile;
  }

  Future<UserProfile> createOrUpdate(UserProfile userProfile) async {
    final updatedUserProfile = userProfile.copyWith(
      createdAt: userProfile.createdAt.toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final docRef = userProfile.userId.isEmpty
        ? _firestore.collection(_collection).doc()
        : _firestore.collection(_collection).doc(userProfile.userId);

    await docRef.set(
      updatedUserProfile.toFirestore(),
      SetOptions(merge: userProfile.userId.isNotEmpty),
    );

    final finalUserProfile = userProfile.userId.isEmpty
        ? updatedUserProfile.copyWith(userId: docRef.id)
        : updatedUserProfile;

    unawaited(_cacheUserProfile(finalUserProfile));

    return finalUserProfile;
  }

  Future<String> uploadProfileImage(String userId, XFile imageFile) async {
    // final ref = _storage.ref().child('$_profileImagePath/$userId');
    // await ref.putData(await imageFile.readAsBytes());
    // final downloadUrl = await ref.getDownloadURL();
    // return downloadUrl;

    throw UnimplementedError('Rework this');
  }

  Future<void> _cacheUserProfile(UserProfile userProfile) async {
    await _userProfileBox.put(userProfile.userId, userProfile);
  }

  UserProfile? _getCachedProfileByCode(String code) {
    return _userProfileBox.values.firstWhereOrNull(
      (profile) => profile.code == code,
    );
  }
}
