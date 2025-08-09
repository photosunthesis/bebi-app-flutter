import 'dart:async';

import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'calendar_event_form_state.dart';
part 'calendar_event_form_cubit.freezed.dart';

@Injectable()
class CalendarEventFormCubit extends Cubit<CalendarEventFormState> {
  CalendarEventFormCubit(
    this._calendarEventsRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
    this._firebaseAnalytics,
  ) : super(const CalendarEventFormState(currentUserId: ''));

  final CalendarEventsRepository _calendarEventsRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;
  final FirebaseAnalytics _firebaseAnalytics;

  Future<void> initialize(CalendarEvent? calendarEvent) async {
    if (calendarEvent == null) return;
    emit(
      state.copyWith(
        calendarEvent: calendarEvent,
        currentUserId: _firebaseAuth.currentUser!.uid,
      ),
    );
  }

  Future<void> save({
    required String title,
    required DateTime date,
    required DateTime startTime,
    DateTime? endTime,
    required bool allDay,
    required EventColor eventColor,
    required RepeatRule repeatRule,
    required bool shareWithPartner,
    String? notes,
    DateTime? endDate,
    DateTime? endRepeatDate,
  }) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));

        final partnership = shareWithPartner
            ? await _userPartnershipsRepository.getByUserId(
                _firebaseAuth.currentUser!.uid,
              )
            : null;

        var updatedEvent = CalendarEvent(
          id: state.calendarEvent?.id ?? '',
          title: title,
          date: date,
          startTime: startTime,
          endTime: allDay ? null : endTime,
          allDay: allDay,
          notes: notes,
          repeatRule: repeatRule,
          eventColor: eventColor,
          createdBy:
              state.calendarEvent?.createdBy ?? _firebaseAuth.currentUser!.uid,
          updatedBy: _firebaseAuth.currentUser!.uid,
          users: shareWithPartner
              ? partnership!.users
              : [_firebaseAuth.currentUser!.uid],
          createdAt: state.calendarEvent?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        updatedEvent = await _calendarEventsRepository.createOrUpdate(
          updatedEvent,
        );

        unawaited(
          _firebaseAnalytics.logEvent(
            name: state.calendarEvent?.id.isNotEmpty ?? false
                ? 'update_calendar_event'
                : 'create_calendar_event',
            parameters: {
              'user_id': _firebaseAuth.currentUser!.uid,
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          ),
        );

        emit(state.copyWith(success: true, calendarEvent: updatedEvent));
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
