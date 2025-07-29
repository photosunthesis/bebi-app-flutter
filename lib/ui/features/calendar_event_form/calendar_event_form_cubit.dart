import 'package:bebi_app/config/firebase_services.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'calendar_event_form_state.dart';

class CalendarEventFormCubit extends Cubit<CalendarEventFormState> {
  CalendarEventFormCubit(
    this._calendarEventsRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
    this._firebaseAnalytics,
  ) : super(const CalendarEventFormState());

  final CalendarEventsRepository _calendarEventsRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;
  final FirebaseAnalytics _firebaseAnalytics;

  Future<void> initialize(String? calendarEventId) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));

        if (calendarEventId == null) return;

        final calendarEvent = await _calendarEventsRepository.getById(
          calendarEventId,
        );

        emit(
          state.copyWith(
            calendarEventId: calendarEventId,
            calendarEvent: calendarEvent,
          ),
        );
      },
      onError: (error, _) {
        emit(state.copyWith(error: error.toString()));
      },
      onComplete: () {
        emit(state.copyWith(loading: false));
      },
    );
  }

  Future<void> save({
    required String title,
    required DateTime startDate,
    required bool allDay,
    required EventColors eventColor,
    required RepeatRule repeatRule,
    required bool shareWithPartner,
    String? notes,
    DateTime? endDate,
    DateTime? endRepeatDate,
    String? location,
  }) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));

        final partnership = shareWithPartner
            ? await _userPartnershipsRepository.getByUserId(
                _firebaseAuth.currentUser!.uid,
              )
            : null;

        await _calendarEventsRepository.createOrUpdate(
          CalendarEvent(
            id: state.calendarEventId ?? '',
            title: title,
            startDate: startDate,
            endDate: endDate,
            allDay: allDay,
            notes: notes,
            repeatRule: repeatRule,
            location: location,
            eventColor: eventColor,
            createdBy: _firebaseAuth.currentUser!.uid,
            partnershipId: partnership?.id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        _firebaseAnalytics.logEvent(
          name: 'create_calendar_event',
          parameters: {
            'user_id': _firebaseAuth.currentUser!.uid,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          },
        );

        emit(state.copyWith(success: true));
      },
      onError: (error, _) {
        emit(state.copyWith(error: error.toString()));
      },
      onComplete: () {
        emit(state.copyWith(loading: false, error: null));
      },
    );
  }
}
