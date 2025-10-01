part of 'calendar_event_form_cubit.dart';

class CalendarEventFormState {
  const CalendarEventFormState({
    required this.title,
    required this.startDate,
    required this.allDay,
    required this.eventColor,
    required this.repeatRule,
    required this.notes,
    required this.currentUserId,
    this.endDate,
    this.originalEvent,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
    this.saveSuccessful = false,
  });

  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  final bool allDay;
  final EventColor eventColor;
  final RepeatRule repeatRule;
  final String notes;
  final String currentUserId;
  final CalendarEvent? originalEvent;
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final bool saveSuccessful;

  bool get eventWasCreatedByCurrentUser =>
      originalEvent == null || originalEvent?.createdBy == currentUserId;

  bool get isEditing => originalEvent != null;

  CalendarEventFormState copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    bool endDateChanged = false,
    bool? allDay,
    EventColor? eventColor,
    RepeatRule? repeatRule,
    String? notes,
    String? currentUserId,
    CalendarEvent? originalEvent,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    bool? saveSuccessful,
  }) {
    return CalendarEventFormState(
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDateChanged ? endDate : (endDate ?? this.endDate),
      allDay: allDay ?? this.allDay,
      eventColor: eventColor ?? this.eventColor,
      repeatRule: repeatRule ?? this.repeatRule,
      notes: notes ?? this.notes,
      currentUserId: currentUserId ?? this.currentUserId,
      originalEvent: originalEvent ?? this.originalEvent,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
      saveSuccessful: saveSuccessful ?? this.saveSuccessful,
    );
  }
}
