import 'dart:ui';

import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/hive_type_ids.dart';
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
    @HiveField(6) required String ownedBy,
    @HiveField(7) required String createdBy,
    @HiveField(8) required DateTime createdAt,
    @HiveField(9) required DateTime updatedAt,
    @HiveField(10) @Default([]) List<String> users,
    @HiveField(11) @Default(false) bool isPrediction,
  }) = _CycleLog;

  factory CycleLog.fromFirestore(DocumentSnapshot doc) {
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

  factory CycleLog.period({
    String id = '',
    required DateTime date,
    required FlowIntensity flow,
    required String ownedBy,
    required String createdBy,
    required List<String> users,
    bool isPrediction = false,
  }) {
    return CycleLog(
      id: id,
      date: date.toUtc(),
      type: LogType.period,
      ownedBy: ownedBy,
      createdBy: createdBy,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      flow: flow,
      users: users,
      isPrediction: isPrediction,
    );
  }

  factory CycleLog.ovulation({
    String id = '',
    required DateTime date,
    required String ownedBy,
    required String createdBy,
    required List<String> users,
    bool isPrediction = false,
  }) {
    return CycleLog(
      id: id,
      date: date.toUtc(),
      type: LogType.ovulation,
      ownedBy: ownedBy,
      createdBy: createdBy,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      users: users,
      isPrediction: isPrediction,
    );
  }

  factory CycleLog.symptom({
    String id = '',
    required DateTime date,
    required String ownedBy,
    required String createdBy,
    required List<String> symptoms,
    required List<String> users,
    bool isPrediction = false,
  }) {
    return CycleLog(
      id: id,
      date: date.toUtc(),
      type: LogType.symptom,
      ownedBy: ownedBy,
      createdBy: createdBy,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      symptoms: symptoms,
      users: users,
      isPrediction: isPrediction,
    );
  }

  factory CycleLog.intimacy({
    String id = '',
    required DateTime date,
    required IntimacyType intimacyType,
    required String ownedBy,
    required String createdBy,
    required List<String> users,
    bool isPrediction = false,
  }) {
    return CycleLog(
      id: id,
      date: date.toUtc(),
      type: LogType.intimacy,
      ownedBy: ownedBy,
      createdBy: createdBy,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      intimacyType: intimacyType,
      users: users,
      isPrediction: isPrediction,
    );
  }

  DateTime get dateLocal => date.toLocal();

  Color get color => switch (type) {
    LogType.period => AppColors.red,
    LogType.ovulation => AppColors.blue,
    LogType.symptom => AppColors.purple,
    LogType.intimacy => AppColors.purple,
  };

  Map<String, dynamic> toFirestore() {
    return {
      // ID is handled by Firestore
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

@HiveType(typeId: HiveTypeIds.cycleLogType)
enum LogType {
  @HiveField(0)
  period,
  @HiveField(1)
  ovulation,
  @HiveField(2)
  symptom,
  @HiveField(3)
  intimacy;

  String get label => name[0].toUpperCase() + name.substring(1);
}

@HiveType(typeId: HiveTypeIds.cycleLogFlowIntensity)
enum FlowIntensity {
  @HiveField(0)
  light,
  @HiveField(1)
  medium,
  @HiveField(2)
  heavy;

  String get label => name[0].toUpperCase() + name.substring(1);
}

@HiveType(typeId: HiveTypeIds.cycleLogIntimacyType)
enum IntimacyType {
  @HiveField(0)
  protected,
  @HiveField(1)
  unprotected;

  String get label => name[0].toUpperCase() + name.substring(1);
}
