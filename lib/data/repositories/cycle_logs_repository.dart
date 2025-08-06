import 'dart:async';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@Injectable()
class CycleLogsRepository {
  const CycleLogsRepository(
    this._firebaseFirestore,
    this._firebaseAuth,
    this._cycleLogBox,
  );

  final FirebaseFirestore _firebaseFirestore;
  final FirebaseAuth _firebaseAuth;
  final Box<CycleLog> _cycleLogBox;

  static const _collection = 'cycle_logs';

  @PostConstruct(preResolve: true)
  Future<void> loadCycleLogsFromServer() async {
    final userId = _firebaseAuth.currentUser?.uid;

    if (userId == null) return;

    final querySnapshot = await _firebaseFirestore
        .collection(_collection)
        .where('users', arrayContains: userId)
        .get();

    final firestoreLogs = querySnapshot.docs
        .map(CycleLog.fromFirestore)
        .toList();

    if (firestoreLogs.isNotEmpty) {
      final newLogsMap = {for (final log in firestoreLogs) log.id: log};
      await _cycleLogBox.putAll(newLogsMap);
    }
  }

  Future<CycleLog> createOrUpdate(CycleLog cycleLog) async {
    final docRef = cycleLog.id.isEmpty
        ? _firebaseFirestore.collection(_collection).doc()
        : _firebaseFirestore.collection(_collection).doc(cycleLog.id);

    await docRef.set(
      cycleLog
          .copyWith(
            updatedAt: DateTime.now().toUtc(),
            createdAt: cycleLog.createdAt.toUtc(),
          )
          .toFirestore(),
      SetOptions(merge: cycleLog.id.isNotEmpty),
    );

    final newCycleLog = cycleLog.copyWith(id: docRef.id);
    unawaited(_cycleLogBox.put(newCycleLog.id, newCycleLog));
    return newCycleLog;
  }

  Future<List<CycleLog>> createMany(List<CycleLog> cycleLogs) async {
    final batch = _firebaseFirestore.batch();
    final newLogs = <CycleLog>[];

    for (final cycleLog in cycleLogs) {
      final docRef = _firebaseFirestore.collection(_collection).doc();
      final newLog = cycleLog.copyWith(
        id: docRef.id,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        date: cycleLog.date.toUtc(),
      );
      newLogs.add(newLog);
      batch.set(docRef, newLog.toFirestore());
    }

    await batch.commit();

    final newLogsMap = {for (final log in newLogs) log.id: log};
    unawaited(_cycleLogBox.putAll(newLogsMap));

    return newLogs;
  }

  Future<void> delete(CycleLog cycleLog) async {
    await _firebaseFirestore.collection(_collection).doc(cycleLog.id).delete();
    unawaited(_cycleLogBox.delete(cycleLog.id));
  }

  Future<List<CycleLog>> getCycleLogsByUserId(
    String userId, {
    bool useCache = true,
  }) async {
    if (useCache) {
      final cachedLogs = _cycleLogBox.values
          .where((log) => log.users.contains(userId))
          .toList();

      if (cachedLogs.isNotEmpty) return cachedLogs;
    }

    final querySnapshot = await _firebaseFirestore
        .collection(_collection)
        .where('users', arrayContains: userId)
        .get();

    final firestoreLogs = querySnapshot.docs
        .map(CycleLog.fromFirestore)
        .toList();

    if (useCache && firestoreLogs.isNotEmpty) {
      final newLogsMap = {for (final log in firestoreLogs) log.id: log};
      await _cycleLogBox.putAll(newLogsMap);
    }

    return firestoreLogs;
  }
}
