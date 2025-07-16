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

  /// Creates a new calendar event.
  ///
  /// Dates will be converted to UTC if they are not already.
  Future<CalendarEvent> create(CalendarEvent event) async {
    final newEvent = event.copyWith(
      startDate: event.startDate.toUtc(),
      endDate: event.endDate?.toUtc(),
      createdAt: event.createdAt.toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final docRef = _firestore.collection(_collection).doc(newEvent.id);
    await docRef.set(newEvent.toFirestore());
    return newEvent;
  }

  /// Updates an existing calendar event.
  ///
  /// Dates will be converted to UTC if they are not already.
  Future<CalendarEvent> update(CalendarEvent event) async {
    final updatedEvent = event.copyWith(
      startDate: event.startDate.toUtc(),
      endDate: event.endDate?.toUtc(),
      createdAt: event.createdAt.toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final docRef = _firestore.collection(_collection).doc(event.id);
    await docRef.update(updatedEvent.toFirestore());
    return updatedEvent;
  }
}
