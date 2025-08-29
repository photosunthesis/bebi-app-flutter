import 'dart:async';

import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/repeat_rule.dart';
import 'package:bebi_app/data/models/save_changes_dialog_options.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/repositories/calendar_events_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/mixins/analytics_mixin.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'calendar_event_form_state.dart';

@injectable
class CalendarEventFormCubit extends Cubit<CalendarEventFormState>
    with GuardMixin, AnalyticsMixin {
  CalendarEventFormCubit(
    this._calendarEventsRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
  ) : super(const CalendarEventFormLoadingState());

  final CalendarEventsRepository _calendarEventsRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;

  void initialize(CalendarEvent? calendarEvent) {
    emit(
      CalendarEventFormLoadedState(
        calendarEvent,
        _firebaseAuth.currentUser!.uid,
      ),
    );

    logEvent(
      name: 'calendar_event_form_opened',
      parameters: {
        'user_id': _firebaseAuth.currentUser!.uid,
        'is_editing': calendarEvent != null,
        'is_recurring_event': calendarEvent?.isRecurring ?? false,
      },
    );
  }

  Future<void> save({
    SaveChangesDialogOptions? saveOption,
    required String title,
    required DateTime startDate,
    required bool allDay,
    required EventColor eventColor,
    required RepeatRule repeatRule,
    DateTime? endDate,
    String? notes,
    DateTime? endRepeatDate,
    DateTime? instanceDate,
  }) async {
    final calendarEvent = (state as CalendarEventFormLoadedState).calendarEvent;

    await guard(
      () async {
        emit(const CalendarEventFormLoadingState());

        final isExistingEvent = calendarEvent?.id.isNotEmpty ?? false;
        final isRecurringEvent = calendarEvent?.isRecurring ?? false;
        final partnership = await _userPartnershipsRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        if (isExistingEvent && isRecurringEvent && instanceDate != null) {
          assert(
            saveOption != null,
            'saveOption must not be null when handling recurring events',
          );
          await _handleRecurringSave(
            baseEvent: calendarEvent!,
            saveOption: saveOption!,
            title: title,
            startDate: startDate,
            endDate: endDate,
            allDay: allDay,
            eventColor: eventColor,
            repeatRule: repeatRule,
            notes: notes,
            instanceDate: instanceDate,
            partnership: partnership!,
          );
        } else {
          await _handleRegularSave(
            title: title,
            startDate: startDate,
            endDate: endDate,
            allDay: allDay,
            eventColor: eventColor,
            repeatRule: repeatRule,
            notes: notes,
            partnership: partnership!,
          );
        }

        logEvent(
          name: isExistingEvent
              ? 'calendar_event_updated'
              : 'calendar_event_created',
          parameters: {
            'user_id': _firebaseAuth.currentUser!.uid,
            'event_type': allDay ? 'all_day' : 'timed',
            'has_repeat': repeatRule.frequency != RepeatFrequency.doNotRepeat,
            'repeat_frequency': repeatRule.frequency.name,
            'has_notes': notes?.isNotEmpty == true,
            'event_color': eventColor.name,
          },
        );

        emit(const CalendarEventFormSuccessState());
      },
      onError: (error, _) {
        emit(CalendarEventFormErrorState(error.toString()));
      },
      onComplete: () {
        emit(
          CalendarEventFormLoadedState(
            calendarEvent,
            _firebaseAuth.currentUser!.uid,
          ),
        );
      },
    );
  }

  Future<void> _handleRegularSave({
    CalendarEvent? calendarEvent,
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    required bool allDay,
    required EventColor eventColor,
    required RepeatRule repeatRule,
    String? notes,
    required UserPartnership partnership,
  }) async {
    await _calendarEventsRepository.createOrUpdate(
      CalendarEvent(
        id: calendarEvent?.id ?? '',
        title: title,
        startDate: startDate,
        endDate: allDay ? null : endDate,
        allDay: allDay,
        notes: notes,
        repeatRule: repeatRule,
        eventColor: eventColor,
        createdBy: calendarEvent?.createdBy ?? _firebaseAuth.currentUser!.uid,
        updatedBy: _firebaseAuth.currentUser!.uid,
        users: partnership.users,
        createdAt: calendarEvent?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _handleRecurringSave({
    required CalendarEvent baseEvent,
    required SaveChangesDialogOptions saveOption,
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    required bool allDay,
    required EventColor eventColor,
    required RepeatRule repeatRule,
    String? notes,
    required DateTime instanceDate,
    required UserPartnership partnership,
  }) async {
    await switch (saveOption) {
      SaveChangesDialogOptions.onlyThisEvent => _handleSaveOnlyThisEvent(
        baseEvent: baseEvent,
        title: title,
        startDate: startDate,
        endDate: endDate,
        allDay: allDay,
        eventColor: eventColor,
        repeatRule: repeatRule,
        notes: notes,
        instanceDate: instanceDate,
        partnership: partnership,
      ),
      SaveChangesDialogOptions.allFutureEvents => _handleSaveAllFutureEvents(
        baseEvent: baseEvent,
        title: title,
        startDate: startDate,
        endDate: endDate,
        allDay: allDay,
        eventColor: eventColor,
        repeatRule: repeatRule,
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
    required DateTime startDate,
    DateTime? endDate,
    required bool allDay,
    required EventColor eventColor,
    required RepeatRule repeatRule,
    String? notes,
    required DateTime instanceDate,
    required UserPartnership partnership,
  }) async {
    if (baseEvent.startDate.isSameDay(instanceDate)) {
      final nextOccurrenceDate = _getNextOccurrence(baseEvent);
      if (nextOccurrenceDate != null) {
        final updatedBaseEvent = baseEvent.copyWith(
          startDate: _updateTimeToNewDate(
            baseEvent.startDate,
            nextOccurrenceDate,
          ),
          endDate: baseEvent.endDate != null
              ? _updateTimeToNewDate(baseEvent.endDate!, nextOccurrenceDate)
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
      startDate: startDate,
      endDate: allDay ? null : endDate,
      allDay: allDay,
      notes: notes,
      repeatRule: const RepeatRule(frequency: RepeatFrequency.doNotRepeat),
      eventColor: eventColor,
      createdBy: _firebaseAuth.currentUser!.uid,
      updatedBy: _firebaseAuth.currentUser!.uid,
      users: partnership.users,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _calendarEventsRepository.createOrUpdate(newSingleEvent);
  }

  Future<void> _handleSaveAllFutureEvents({
    required CalendarEvent baseEvent,
    required String title,
    required DateTime startDate,
    DateTime? endDate,
    required bool allDay,
    required EventColor eventColor,
    required RepeatRule repeatRule,
    String? notes,
    required DateTime instanceDate,
    required UserPartnership partnership,
  }) async {
    if (!baseEvent.startDate.isSameDay(instanceDate)) {
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
      startDate: startDate,
      endDate: allDay ? null : endDate,
      allDay: allDay,
      notes: notes,
      repeatRule: repeatRule,
      eventColor: eventColor,
      createdBy: _firebaseAuth.currentUser!.uid,
      updatedBy: _firebaseAuth.currentUser!.uid,
      users: partnership.users,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _calendarEventsRepository.createOrUpdate(newRecurringEvent);
  }

  DateTime? _getNextOccurrence(CalendarEvent event) {
    final currentDate = event.startDate;
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
