import 'package:bebi_app/constants/hive_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'cycle_log.freezed.dart';
part 'cycle_log.g.dart';

@freezed
abstract class CycleLog with _$CycleLog {
  const CycleLog._();

  @HiveType(typeId: HiveTypeIds.cycleLog)
  factory CycleLog({
    @HiveField(0) required String id,
    @HiveField(1) required DateTime date,
    @HiveField(2) required LogType type,
    @HiveField(3) FlowIntensity? flow,
    @HiveField(4) List<String>? symptoms,
    @HiveField(5) IntimacyType? intimacyType,
    @HiveField(6) required String createdBy,
    @HiveField(7) required DateTime createdAt,
    @HiveField(8) required DateTime updatedAt,
    @HiveField(9) @Default([]) List<String> users,
    @HiveField(10) @Default(false) bool isPrediction,
  }) = _CycleLog;

  factory CycleLog.fromFirestore(DocumentSnapshot doc) {
    return CycleLog(
      id: doc.id,
      date: doc['date'].toDate(),
      type: LogType.values[doc['type']],
      flow: doc['flow'] != null ? FlowIntensity.values[doc['flow']] : null,
      symptoms: doc['symptoms'],
      intimacyType: doc['intimacy_type'] != null
          ? IntimacyType.values[doc['intimacy_type']]
          : null,
      createdBy: doc['created_by'],
      createdAt: doc['created_at'].toDate(),
      updatedAt: doc['updated_at'].toDate(),
      users: doc['users'],
      isPrediction: doc['is_prediction'],
    );
  }

  factory CycleLog.period({
    required String id,
    required DateTime date,
    required FlowIntensity flow,
    required String createdBy,
    required List<String> users,
    required bool isPrediction,
  }) {
    return CycleLog(
      id: id,
      date: date,
      type: LogType.period,
      createdBy: createdBy,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      flow: flow,
      users: users,
      isPrediction: isPrediction,
    );
  }

  factory CycleLog.ovulation({
    required String id,
    required DateTime date,
    required String createdBy,
    required List<String> users,
    required bool isPrediction,
  }) {
    return CycleLog(
      id: id,
      date: date,
      type: LogType.ovulation,
      createdBy: createdBy,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      users: users,
      isPrediction: isPrediction,
    );
  }

  factory CycleLog.symptom({
    required String id,
    required DateTime date,
    required String createdBy,
    required List<String> symptoms,
    required List<String> users,
    required bool isPrediction,
  }) {
    return CycleLog(
      id: id,
      date: date,
      type: LogType.symptom,
      createdBy: createdBy,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      symptoms: symptoms,
      users: users,
      isPrediction: isPrediction,
    );
  }

  DateTime get dateLocal => date.toLocal();

  Map<String, dynamic> toFirestore() {
    return {
      // ID is handled by Firestore
      'date': date,
      'type': type.index,
      'flow': flow?.index,
      'symptoms': symptoms,
      'intimacy_type': intimacyType?.index,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'users': users,
      'is_prediction': isPrediction,
    };
  }
}

@HiveType(typeId: HiveTypeIds.cycleLogType)
enum LogType {
  @HiveField(0)
  period,
  @HiveField(1)
  ovulation,
  @HiveField(2)
  symptom,
  @HiveField(3)
  intimacy,
}

@HiveType(typeId: HiveTypeIds.cycleLogFlowIntensity)
enum FlowIntensity {
  @HiveField(0)
  light,
  @HiveField(1)
  medium,
  @HiveField(2)
  heavy,
}

@HiveType(typeId: HiveTypeIds.cycleLogIntimacyType)
enum IntimacyType {
  @HiveField(0)
  protected,
  @HiveField(1)
  unprotected,
}
