import 'dart:async';

import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

@injectable
class CalendarEventsRepository {
  const CalendarEventsRepository(this._firestore, this._calendarEventBox);

  final FirebaseFirestore _firestore;
  final Box<CalendarEvent> _calendarEventBox;

  static const _collection = 'calendar_events';

  Future<List<CalendarEvent>> getByUserId({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    if (useCache) {
      final cachedEvents = _getCachedEvents(userId, startDate, endDate);
      if (cachedEvents.isNotEmpty) return cachedEvents;
    }

    var userEventsQuery = _firestore
        .collection(_collection)
        .where('users', arrayContains: userId);

    if (startDate != null) {
      userEventsQuery = userEventsQuery.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      userEventsQuery = userEventsQuery.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    final userEvents = await userEventsQuery.get();
    final events = userEvents.docs.map(CalendarEvent.fromFirestore).toList();

    unawaited(_cacheEvents(events));

    return events;
  }

  Future<CalendarEvent?> getById(String id, {bool useCache = true}) async {
    if (useCache) {
      final cachedEvent = _calendarEventBox.values.firstWhereOrNull(
        (e) => e.id == id,
      );

      if (cachedEvent != null) return cachedEvent;
    }

    final docRef = _firestore.collection(_collection).doc(id);
    final docSnapshot = await docRef.get();
    final event = docSnapshot.exists
        ? CalendarEvent.fromFirestore(docSnapshot)
        : null;

    if (event != null) unawaited(_cacheEvents(<CalendarEvent>[event]));

    return event;
  }

  Future<CalendarEvent> createOrUpdate(CalendarEvent event) async {
    final eventsCollection = _firestore.collection(_collection);
    final eventDoc = event.id.isEmpty
        ? eventsCollection.doc()
        : eventsCollection.doc(event.id);

    await eventDoc.set(
      event.toFirestore(),
      SetOptions(merge: event.id.isEmpty),
    );

    final returnedEvent = event.id.isEmpty
        ? event.copyWith(id: eventDoc.id)
        : event;

    unawaited(_cacheEvents(<CalendarEvent>[returnedEvent]));

    return returnedEvent;
  }

  Future<void> deleteById(String calendarEventId) async {
    await Future.wait(<Future<void>>[
      _calendarEventBox.delete(calendarEventId),
      _firestore.collection(_collection).doc(calendarEventId).delete(),
    ]);
  }

  List<CalendarEvent> _getCachedEvents(
    String userId,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return _calendarEventBox.values.where((event) {
      if (!event.users.contains(userId)) return false;

      // Check if the event is within the date range
      if (startDate != null &&
          event.startDate.isBefore(startDate) &&
          !event.startDate.isSameDay(startDate)) {
        return false;
      }

      if (endDate != null &&
          event.startDate.isAfter(endDate) &&
          !event.startDate.isSameDay(endDate)) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _cacheEvents(List<CalendarEvent> events) async {
    await _calendarEventBox.putAll(
      Map.fromEntries(events.map((e) => MapEntry(e.id, e))),
    );
  }
}
