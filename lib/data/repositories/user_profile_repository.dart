import 'dart:io';

import 'package:bebi_app/data/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserProfileRepository {
  const UserProfileRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _collection = 'user_profiles';
  static const _profileImagePath = 'profile_images';

  Future<UserProfile?> getByUserId(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<UserProfile?> getByUserCode(String code) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return UserProfile.fromFirestore(querySnapshot.docs.first);
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

    return updatedUserProfile;
  }

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    final ref = _storage.ref().child('$_profileImagePath/$userId');
    await ref.putFile(imageFile);
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }
}
