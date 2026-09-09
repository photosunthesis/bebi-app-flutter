import 'package:bebi_app/features/account/domain/user_partnership.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension UserPartnershipDto on UserPartnership {
  static UserPartnership fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserPartnership(
      id: doc.id,
      users: (data['users'] as List<dynamic>).map((e) => e as String).toList(),
      createdBy: data['created_by'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate().toUtc(),
      updatedAt: (data['updated_at'] as Timestamp).toDate().toUtc(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'users': users,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt.toUtc()),
      'updated_at': Timestamp.fromDate(updatedAt.toUtc()),
    };
  }
}
