import 'dart:ui';

import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/constants/hive_type_ids.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'cycle_log.g.dart';

class CycleLog extends Equatable {
  @HiveType(typeId: HiveTypeIds.cycleLog)
  CycleLog._({
    required this.id,
    required DateTime date,
    required this.type,
    this.flow,
    this.symptoms,
    this.intimacyType,
    required this.ownedBy,
    required this.createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.users = const [],
    this.isPrediction = false,
  }) : _date = date.toUtc(),
       _createdAt = createdAt.toUtc(),
       _updatedAt = updatedAt.toUtc();

  factory CycleLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CycleLog._(
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
    return CycleLog._(
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
    return CycleLog._(
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
    return CycleLog._(
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
    return CycleLog._(
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

  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime _date;
  @HiveField(2)
  final LogType type;
  @HiveField(3)
  final FlowIntensity? flow;
  @HiveField(4)
  final List<String>? symptoms;
  @HiveField(5)
  final IntimacyType? intimacyType;
  @HiveField(6)
  final String ownedBy;
  @HiveField(7)
  final String createdBy;
  @HiveField(8)
  final DateTime _createdAt;
  @HiveField(9)
  final DateTime _updatedAt;
  @HiveField(10)
  final List<String> users;
  @HiveField(11)
  final bool isPrediction;

  DateTime get date => _date.toLocal();
  DateTime get createdAt => _createdAt.toLocal();
  DateTime get updatedAt => _updatedAt.toLocal();

  Color get color => switch (type) {
    LogType.period => AppColors.red,
    LogType.ovulation => AppColors.blue,
    LogType.symptom => AppColors.purple,
    LogType.intimacy => AppColors.purple,
  };

  CycleLog copyWith({
    String? id,
    DateTime? date,
    LogType? type,
    FlowIntensity? flow,
    List<String>? symptoms,
    IntimacyType? intimacyType,
    String? ownedBy,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? users,
    bool? isPrediction,
  }) {
    return CycleLog._(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      flow: flow ?? this.flow,
      symptoms: symptoms ?? this.symptoms,
      intimacyType: intimacyType ?? this.intimacyType,
      ownedBy: ownedBy ?? this.ownedBy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      users: users ?? this.users,
      isPrediction: isPrediction ?? this.isPrediction,
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

  @override
  List<Object?> get props => [
    id,
    date,
    type,
    flow,
    symptoms,
    intimacyType,
    ownedBy,
    createdBy,
    createdAt,
    updatedAt,
    users,
    isPrediction,
  ];
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
