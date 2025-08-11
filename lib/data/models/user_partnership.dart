import 'package:bebi_app/constants/hive_type_ids.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'user_partnership.freezed.dart';
part 'user_partnership.g.dart';

@freezed
abstract class UserPartnership with _$UserPartnership {
  const UserPartnership._();

  @HiveType(typeId: HiveTypeIds.userPartnership)
  const factory UserPartnership({
    @HiveField(0) required String id,
    @HiveField(1) required List<String> users,
    @HiveField(2) required String createdBy,
    @HiveField(3) required DateTime createdAt,
    @HiveField(4) required DateTime updatedAt,
  }) = _UserPartnership;

  factory UserPartnership.fromFirestore(DocumentSnapshot doc) {
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
      // ID is managed by Firestore
      'users': users,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt.toUtc()),
      'updated_at': Timestamp.fromDate(updatedAt.toUtc()),
    };
  }
}
