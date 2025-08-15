part of 'home_cubit.dart';

@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.loading() = HomeLoadingState;
  const factory HomeState.error(String message) = HomeErrorState;
  const factory HomeState.data({required UserProfile currentUser}) =
      HomeDataState;
  const factory HomeState.shouldSetUpProfile() = HomeShouldSetUpProfileState;
  const factory HomeState.shouldConfirmEmail() = HomeShouldConfirmEmailState;
  const factory HomeState.shouldAddPartner() = HomeShouldAddPartnerState;
  const factory HomeState.shouldUpdateApp(AppUpdateInfo info) =
      HomeShouldUpdateAppState;
}
