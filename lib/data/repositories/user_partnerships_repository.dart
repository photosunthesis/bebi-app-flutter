import 'dart:async';

import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class UserPartnershipsRepository {
  const UserPartnershipsRepository(this._firestore, this._userPartnershipBox);

  final FirebaseFirestore _firestore;
  final Box<UserPartnership> _userPartnershipBox;

  static const _collection = 'user_partnerships';

  Future<UserPartnership?> getByUserId(
    String userId, {
    bool useCache = true,
  }) async {
    if (useCache) {
      final cachedPartnership = _getCachedPartnershipByUserId(userId);
      if (cachedPartnership != null) return cachedPartnership;
    }

    final querySnapshot = await _firestore
        .collection(_collection)
        .where('users', arrayContains: userId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    final partnership = UserPartnership.fromFirestore(querySnapshot.docs.first);
    unawaited(_cachePartnership(partnership));
    return partnership;
  }

  Future<UserPartnership> create(UserPartnership partnership) async {
    final collectionRef = _firestore.collection(_collection);
    final docRef = await collectionRef.add(partnership.toFirestore());
    final createdPartnership = partnership.copyWith(id: docRef.id);
    unawaited(_cachePartnership(createdPartnership));
    return createdPartnership;
  }

  Future<UserPartnership> update(UserPartnership partnership) async {
    final docRef = _firestore.collection(_collection).doc(partnership.id);
    await docRef.update(partnership.toFirestore());
    unawaited(_cachePartnership(partnership));
    return partnership;
  }

  Future<void> _cachePartnership(UserPartnership partnership) async {
    await _userPartnershipBox.put(partnership.id, partnership);
  }

  // Helper method to get a cached partnership by user ID
  UserPartnership? _getCachedPartnershipByUserId(String userId) {
    return _userPartnershipBox.values.firstWhereOrNull(
      (p) => p.users.contains(userId),
    );
  }
}
