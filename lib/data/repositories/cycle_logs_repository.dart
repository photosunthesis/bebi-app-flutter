import 'dart:async';

import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@injectable
class CycleLogsRepository {
  const CycleLogsRepository(this._firestore, this._cycleLogBox);

  final FirebaseFirestore _firestore;
  final Box<CycleLog> _cycleLogBox;

  static const _collection = 'cycle_logs';

  Future<CycleLog?> getById(String id) async {
    final cycleLog = _cycleLogBox.get(id);
    if (cycleLog != null) return cycleLog;

    final docSnapshot = await _firestore.collection(_collection).doc(id).get();

    if (docSnapshot.exists) {
      final cycleLog = CycleLog.fromFirestore(docSnapshot);
      unawaited(_cycleLogBox.put(cycleLog.id, cycleLog));
      return cycleLog;
    }

    return null;
  }

  Future<List<CycleLog>> getByUserIdAndDateRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('owned_by', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final firestoreLogs = querySnapshot.docs
        .map(CycleLog.fromFirestore)
        .toList();

    return firestoreLogs;
  }

  Future<CycleLog> createOrUpdate(CycleLog cycleLog) async {
    final docRef = cycleLog.id.isEmpty
        ? _firestore.collection(_collection).doc()
        : _firestore.collection(_collection).doc(cycleLog.id);

    await docRef.set(cycleLog.toFirestore());

    final newCycleLog = cycleLog.copyWith(id: docRef.id);
    unawaited(_cycleLogBox.put(newCycleLog.id, newCycleLog));
    return newCycleLog;
  }

  Future<List<CycleLog>> createMany(List<CycleLog> cycleLogs) async {
    final batch = _firestore.batch();
    final newLogs = <CycleLog>[];

    for (final cycleLog in cycleLogs) {
      final docRef = _firestore.collection(_collection).doc();
      final newLog = cycleLog.copyWith(id: docRef.id);
      newLogs.add(newLog);
      batch.set(docRef, newLog.toFirestore());
    }

    await batch.commit();

    final newLogsMap = {for (final log in newLogs) log.id: log};
    unawaited(_cycleLogBox.putAll(newLogsMap));

    return newLogs;
  }

  Future<void> deleteById(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
    unawaited(_cycleLogBox.delete(id));
  }

  Future<List<CycleLog>> getCycleLogsByUserId(
    String userId, {
    bool useCache = true,
  }) async {
    if (useCache) {
      final cachedLogs = _cycleLogBox.values
          .where((log) => log.ownedBy == userId)
          .toList();

      if (cachedLogs.isNotEmpty) return cachedLogs;
    }

    final querySnapshot = await _firestore
        .collection(_collection)
        .where('owned_by', isEqualTo: userId)
        .get();

    final firestoreLogs = querySnapshot.docs
        .map(CycleLog.fromFirestore)
        .toList();

    if (firestoreLogs.isNotEmpty) {
      final newLogsMap = {for (final log in firestoreLogs) log.id: log};
      await _cycleLogBox.putAll(newLogsMap);
    }

    return firestoreLogs;
  }
}
