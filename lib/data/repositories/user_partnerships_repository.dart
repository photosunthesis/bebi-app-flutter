import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPartnershipsRepository {
  const UserPartnershipsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _collection = 'user_partnerships';

  Future<UserPartnership?> getByUserId(String userId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('users', arrayContains: userId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return UserPartnership.fromFirestore(querySnapshot.docs.first);
  }

  Future<UserPartnership> create(UserPartnership partnership) async {
    final collectionRef = _firestore.collection(_collection);
    final docRef = await collectionRef.add(partnership.toFirestore());
    return partnership.copyWith(id: docRef.id);
  }

  Future<UserPartnership> update(UserPartnership partnership) async {
    final docRef = _firestore.collection(_collection).doc(partnership.id);
    await docRef.update(partnership.toFirestore());
    return partnership;
  }
}
