import 'dart:ui';

import 'package:bebi_app/app/theme/app_colors.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CycleLog extends Equatable {
  CycleLog({
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
  }) : _date = date.noTime(),
       _createdAt = createdAt.toUtc(),
       _updatedAt = updatedAt.toUtc();

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
      date: date,
      type: LogType.period,
      ownedBy: ownedBy,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
      date: date,
      type: LogType.ovulation,
      ownedBy: ownedBy,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
      date: date,
      type: LogType.symptom,
      ownedBy: ownedBy,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
      date: date,
      type: LogType.intimacy,
      ownedBy: ownedBy,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      intimacyType: intimacyType,
      users: users,
      isPrediction: isPrediction,
    );
  }

  final String id;
  final DateTime _date;
  final LogType type;
  final FlowIntensity? flow;
  final List<String>? symptoms;
  final IntimacyType? intimacyType;
  final String ownedBy;
  final String createdBy;
  final DateTime _createdAt;
  final DateTime _updatedAt;
  final List<String> users;
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
    return CycleLog(
      id: id ?? this.id,
      date: date?.noTime() ?? this.date,
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

enum LogType {
  period,
  ovulation,
  symptom,
  intimacy;

  String get label => name[0].toUpperCase() + name.substring(1);
}

enum FlowIntensity {
  light,
  medium,
  heavy;

  String get label => name[0].toUpperCase() + name.substring(1);
}

enum IntimacyType {
  protected,
  unprotected;

  String get label => name[0].toUpperCase() + name.substring(1);
}
