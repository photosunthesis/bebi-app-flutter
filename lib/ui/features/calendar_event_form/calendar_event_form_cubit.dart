import 'dart:async';

import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/event_color.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/data/models/save_changes_dialog_options.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/utils/extension/datetime_extensions.dart';
import 'package:bebi_app/utils/extension/int_extensions.dart';
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
    required SaveChangesDialogOptions saveOption,
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
    DateTime? instanceDate,
  }) async {
    await guard(
      () async {
        emit(state.copyWith(loading: true));

        final partnership = shareWithPartner
            ? await _userPartnershipsRepository.getByUserId(
                _firebaseAuth.currentUser!.uid,
              )
            : null;

        final isExistingEvent = state.calendarEvent?.id.isNotEmpty ?? false;
        final isRecurringEvent = state.calendarEvent?.isRecurring ?? false;

        if (isExistingEvent && isRecurringEvent && instanceDate != null) {
          await _handleRecurringSave(
            saveOption: saveOption,
            title: title,
            date: date,
            startTime: startTime,
            endTime: endTime,
            allDay: allDay,
            eventColor: eventColor,
            repeatRule: repeatRule,
            shareWithPartner: shareWithPartner,
            notes: notes,
            instanceDate: instanceDate,
            partnership: partnership,
          );
        } else {
          await _handleRegularSave(
            title: title,
            date: date,
            startTime: startTime,
            endTime: endTime,
            allDay: allDay,
            eventColor: eventColor,
            repeatRule: repeatRule,
            shareWithPartner: shareWithPartner,
            notes: notes,
            partnership: partnership,
          );
        }

        unawaited(
          _firebaseAnalytics.logEvent(
            name: isExistingEvent
                ? 'update_calendar_event'
                : 'create_calendar_event',
            parameters: {
              'user_id': _firebaseAuth.currentUser!.uid,
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          ),
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

  Future<void> _handleRegularSave({
    required String title,
    required DateTime date,
    required DateTime startTime,
    DateTime? endTime,
    required bool allDay,
    required EventColor eventColor,
    required RepeatRule repeatRule,
    required bool shareWithPartner,
    String? notes,
    partnership,
  }) async {
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

    updatedEvent = await _calendarEventsRepository.createOrUpdate(updatedEvent);

    emit(state.copyWith(calendarEvent: updatedEvent));
  }

  Future<void> _handleRecurringSave({
    required SaveChangesDialogOptions saveOption,
    required String title,
    required DateTime date,
    required DateTime startTime,
    DateTime? endTime,
    required bool allDay,
    required EventColor eventColor,
    required RepeatRule repeatRule,
    required bool shareWithPartner,
    String? notes,
    required DateTime instanceDate,
    partnership,
  }) async {
    final baseEvent = state.calendarEvent!;

    await switch (saveOption) {
      SaveChangesDialogOptions.onlyThisEvent => _handleSaveOnlyThisEvent(
        baseEvent: baseEvent,
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
        allDay: allDay,
        eventColor: eventColor,
        repeatRule: repeatRule,
        shareWithPartner: shareWithPartner,
        notes: notes,
        instanceDate: instanceDate,
        partnership: partnership,
      ),
      SaveChangesDialogOptions.allFutureEvents => _handleSaveAllFutureEvents(
        baseEvent: baseEvent,
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
        allDay: allDay,
        eventColor: eventColor,
        repeatRule: repeatRule,
        shareWithPartner: shareWithPartner,
        notes: notes,
        instanceDate: instanceDate,
        partnership: partnership,
      ),
      SaveChangesDialogOptions.cancel => null,
    };
  }

  Future<void> _handleSaveOnlyThisEvent({
    required CalendarEvent baseEvent,
    required String title,
    required DateTime date,
    required DateTime startTime,
    DateTime? endTime,
    required bool allDay,
    required EventColor eventColor,
    required RepeatRule repeatRule,
    required bool shareWithPartner,
    String? notes,
    required DateTime instanceDate,
    partnership,
  }) async {
    if (baseEvent.date.isSameDay(instanceDate)) {
      final nextOccurrenceDate = _getNextOccurrence(baseEvent);
      if (nextOccurrenceDate != null) {
        final updatedBaseEvent = baseEvent.copyWith(
          date: nextOccurrenceDate,
          startTime: _updateTimeToNewDate(
            baseEvent.startTime,
            nextOccurrenceDate,
          ),
          endTime: baseEvent.endTime != null
              ? _updateTimeToNewDate(baseEvent.endTime!, nextOccurrenceDate)
              : null,
        );
        await _calendarEventsRepository.createOrUpdate(updatedBaseEvent);
      } else {
        await _calendarEventsRepository.deleteById(baseEvent.id);
      }
    } else {
      final updatedExcludedDates = Set<DateTime>.from(
        baseEvent.repeatRule.excludedDates ?? [],
      )..add(instanceDate);

      final updatedBaseEvent = baseEvent.copyWith(
        repeatRule: baseEvent.repeatRule.copyWith(
          excludedDates: updatedExcludedDates.toList(),
        ),
      );
      await _calendarEventsRepository.createOrUpdate(updatedBaseEvent);
    }

    final newSingleEvent = CalendarEvent(
      id: '',
      title: title,
      date: date,
      startTime: startTime,
      endTime: allDay ? null : endTime,
      allDay: allDay,
      notes: notes,
      repeatRule: const RepeatRule(frequency: RepeatFrequency.doNotRepeat),
      eventColor: eventColor,
      createdBy: _firebaseAuth.currentUser!.uid,
      updatedBy: _firebaseAuth.currentUser!.uid,
      users: shareWithPartner
          ? partnership!.users
          : [_firebaseAuth.currentUser!.uid],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final createdEvent = await _calendarEventsRepository.createOrUpdate(
      newSingleEvent,
    );
    emit(state.copyWith(calendarEvent: createdEvent));
  }

  Future<void> _handleSaveAllFutureEvents({
    required CalendarEvent baseEvent,
    required String title,
    required DateTime date,
    required DateTime startTime,
    DateTime? endTime,
    required bool allDay,
    required EventColor eventColor,
    required RepeatRule repeatRule,
    required bool shareWithPartner,
    String? notes,
    required DateTime instanceDate,
    partnership,
  }) async {
    if (!baseEvent.date.isSameDay(instanceDate)) {
      final updatedBaseEvent = baseEvent.copyWith(
        repeatRule: baseEvent.repeatRule.copyWith(
          endDate: instanceDate.subtract(1.days),
        ),
      );
      await _calendarEventsRepository.createOrUpdate(updatedBaseEvent);
    } else {
      await _calendarEventsRepository.deleteById(baseEvent.id);
    }

    final newRecurringEvent = CalendarEvent(
      id: '',
      title: title,
      date: date,
      startTime: startTime,
      endTime: allDay ? null : endTime,
      allDay: allDay,
      notes: notes,
      repeatRule: repeatRule,
      eventColor: eventColor,
      createdBy: _firebaseAuth.currentUser!.uid,
      updatedBy: _firebaseAuth.currentUser!.uid,
      users: shareWithPartner
          ? partnership!.users
          : [_firebaseAuth.currentUser!.uid],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final createdEvent = await _calendarEventsRepository.createOrUpdate(
      newRecurringEvent,
    );
    emit(state.copyWith(calendarEvent: createdEvent));
  }

  DateTime? _getNextOccurrence(CalendarEvent event) {
    final currentDate = event.date;
    return switch (event.repeatRule.frequency) {
      RepeatFrequency.daily => currentDate.add(1.days),
      RepeatFrequency.weekly => currentDate.add(7.days),
      RepeatFrequency.monthly => DateTime(
        currentDate.year,
        currentDate.month + 1,
        currentDate.day,
      ),
      RepeatFrequency.yearly => DateTime(
        currentDate.year + 1,
        currentDate.month,
        currentDate.day,
      ),
      // TODO Handle other repeat frequencies
      _ => null,
    };
  }

  DateTime _updateTimeToNewDate(DateTime time, DateTime newDate) {
    return DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      time.hour,
      time.minute,
    );
  }
}
