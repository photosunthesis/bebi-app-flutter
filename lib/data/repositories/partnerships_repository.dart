import 'package:bebi_app/data/models/partnership.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PartnershipsRepository {
  const PartnershipsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _collection = 'partnerships';

  Future<Partnership?> getByUserId(String userId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('users', arrayContains: {'id': userId})
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return Partnership.fromFirestore(querySnapshot.docs.first);
  }

  Future<Partnership?> getByCode(String code) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return Partnership.fromFirestore(querySnapshot.docs.first);
  }

  Future<Partnership> create(Partnership partnership) async {
    final docRef = _firestore.collection(_collection).doc();
    await docRef.set(partnership.toFirestore());
    return partnership.copyWith(id: docRef.id);
  }

  Future<void> update(Partnership partnership) async {
    if (partnership.id.isEmpty) {
      throw ArgumentError('Partnership must have an ID to be updated.');
    }

    await _firestore
        .collection(_collection)
        .doc(partnership.id)
        .update(partnership.toFirestore());
  }
}
