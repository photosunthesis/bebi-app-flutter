import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEventsRepository {
  const CalendarEventsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _collection = 'calendar_events';

  Future<List<CalendarEvent>> getEventsByUserId(String userId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('users', arrayContains: {'id': userId})
        .get();

    return querySnapshot.docs.map(CalendarEvent.fromFirestore).toList();
  }

  Future<CalendarEvent?> getById(String id) async {
    final docRef = _firestore.collection(_collection).doc(id);
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return null;
    return CalendarEvent.fromFirestore(docSnapshot);
  }

  /// Creates or updates a calendar event.
  ///
  /// Dates will be converted to UTC if they are not already.
  Future<CalendarEvent> createOrUpdate(CalendarEvent event) async {
    final updatedEvent = event.copyWith(
      startDate: event.startDate.toUtc(),
      endDate: event.endDate?.toUtc(),
      createdAt: event.createdAt.toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final docRef = event.id.isEmpty
        ? _firestore.collection(_collection).doc()
        : _firestore.collection(_collection).doc(event.id);

    await docRef.set(
      updatedEvent.toFirestore(),
      SetOptions(merge: event.id.isNotEmpty),
    );

    return updatedEvent;
  }
}
