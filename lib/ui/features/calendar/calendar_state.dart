part of 'calendar_cubit.dart';

@freezed
abstract class CalendarState with _$CalendarState {
  const factory CalendarState({
    required DateTime focusedDay,
    @Default([]) List<CalendarEvent> events,
    @Default([]) List<CalendarEvent> focusedDayEvents,
    @Default(false) bool loading,
    UserProfile? userProfile,
    UserProfile? partnerProfile,
    String? error,
  }) = _CalendarState;

  factory CalendarState.initial() => CalendarState(focusedDay: DateTime.now());
}
