import 'package:bebi_app/features/cycles/domain/cycle_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension CycleLogDto on CycleLog {
  static CycleLog fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CycleLog(
      id: doc.id,
      date: data['date'].toDate(),
      type: LogType.values[data['type']],
      flow: data['flow'] != null ? FlowIntensity.values[data['flow']] : null,
      symptoms: data['symptoms'] != null
          ? List<String>.from(data['symptoms'] as List<dynamic>)
          : null,
      intimacyType: data['intimacy_type'] != null
          ? IntimacyType.values[data['intimacy_type']]
          : null,
      createdBy: data['created_by'],
      ownedBy: data['owned_by'],
      createdAt: data['created_at'].toDate(),
      updatedAt: data['updated_at'].toDate(),
      users: List<String>.from(data['users'] as List<dynamic>),
      isPrediction: data['is_prediction'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'type': type.index,
      'flow': flow?.index,
      'symptoms': symptoms,
      'intimacy_type': intimacyType?.index,
      'owned_by': ownedBy,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'users': users,
      'is_prediction': isPrediction,
    };
  }
}
