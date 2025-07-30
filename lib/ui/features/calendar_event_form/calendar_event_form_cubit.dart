import 'package:bebi_app/config/firebase_services.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event_form_state.dart';
part 'calendar_event_form_cubit.freezed.dart';

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

  Future<void> initialize(CalendarEvent? calendarEvent) async {
    emit(state.copyWith(loading: true));
    if (calendarEvent == null) return;
    emit(state.copyWith(calendarEvent: calendarEvent));
  }

  Future<void> save({
    required String title,
    required DateTime date,
    required DateTime startTime,
    DateTime? endTime,
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

        final calendarEvent = state.calendarEvent;
        await _calendarEventsRepository.createOrUpdate(
          CalendarEvent(
            id: calendarEvent?.id ?? '',
            title: title,
            date: date,
            startTime: startTime,
            endTime: allDay ? null : endTime,
            allDay: allDay,
            notes: notes,
            repeatRule: repeatRule,
            location: location,
            eventColor: eventColor,
            createdBy:
                calendarEvent?.createdBy ?? _firebaseAuth.currentUser!.uid,
            users: partnership?.users ?? [_firebaseAuth.currentUser!.uid],
            createdAt: calendarEvent?.createdAt ?? DateTime.now(),
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
