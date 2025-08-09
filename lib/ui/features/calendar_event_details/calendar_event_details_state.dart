part of 'calendar_event_details_cubit.dart';

@freezed
sealed class CalendarEventDetailsState with _$CalendarEventDetailsState {
  const factory CalendarEventDetailsState.loading() =
      CalendarEventDetailsStateLoading;
  const factory CalendarEventDetailsState.data(
    UserProfile userProfile,
    UserProfile partnerProfile,
  ) = CalendarEventDetailsStateData;
  const factory CalendarEventDetailsState.error(String error) =
      CalendarEventDetailsStateError;
  const factory CalendarEventDetailsState.deleteSuccess() =
      CalendarEventDetailsStateDeleteSuccess;
}
