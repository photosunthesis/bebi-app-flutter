import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEventsRepository {
  const CalendarEventsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _collection = 'calendar_events';

  Future<List<CalendarEvent>> getByUserId({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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

    return userEvents.docs.map(CalendarEvent.fromFirestore).toList();
  }

  Future<CalendarEvent?> getById(String id) async {
    final docRef = _firestore.collection(_collection).doc(id);
    final docSnapshot = await docRef.get();
    return docSnapshot.exists ? CalendarEvent.fromFirestore(docSnapshot) : null;
  }

  Future<CalendarEvent> createOrUpdate(CalendarEvent event) async {
    final updatedEvent = event.copyWith(
      date: event.date.toUtc(),
      startTime: event.startTime.toUtc(),
      endTime: event.endTime?.toUtc(),
      createdAt: event.createdAt.toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final eventsCollection = _firestore.collection(_collection);
    final eventDoc = event.id.isEmpty
        ? eventsCollection.doc()
        : eventsCollection.doc(event.id);

    await eventDoc.set(
      updatedEvent.toFirestore(),
      SetOptions(merge: event.id.isEmpty),
    );

    return updatedEvent;
  }
}
