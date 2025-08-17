part of 'home_cubit.dart';

sealed class HomeState {
  const HomeState();
}

class HomeLoadingState extends HomeState {
  const HomeLoadingState();
}

class HomeErrorState extends HomeState {
  const HomeErrorState(this.message);
  final String message;
}

class HomeLoadedState extends HomeState {
  const HomeLoadedState(this.currentUser);
  final UserProfile currentUser;
}

class HomeShouldSetUpProfileState extends HomeState {
  const HomeShouldSetUpProfileState();
}

class HomeShouldConfirmEmailState extends HomeState {
  const HomeShouldConfirmEmailState();
}

class HomeShouldAddPartnerState extends HomeState {
  const HomeShouldAddPartnerState();
}

class HomeShouldUpdateAppState extends HomeState {
  const HomeShouldUpdateAppState(this.info);
  final AppUpdateInfo info;
}
