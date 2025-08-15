part of 'home_cubit.dart';

@freezed
sealed class HomeState with _$HomeState {
  const factory HomeState.initial() = HomeInitial;
  const factory HomeState.loading() = HomeLoading;
  const factory HomeState.error(String message) = HomeError;
  const factory HomeState.loaded({required UserProfile currentUser}) =
      HomeLoaded;
  const factory HomeState.shouldSetUpProfile() = HomeShouldSetUpProfile;
  const factory HomeState.shouldConfirmEmail() = HomeShouldConfirmEmail;
  const factory HomeState.shouldAddPartner() = HomeShouldAddPartner;
  const factory HomeState.shouldUpdateApp(AppUpdateInfo info) =
      HomeShouldUpdateApp;
}
