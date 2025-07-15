part of 'home_cubit.dart';

sealed class HomeState {
  const HomeState();
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
}

class HomeLoaded extends HomeState {
  const HomeLoaded({required this.currentUser, this.partnership});
  final UserProfile currentUser;
  final Partnership? partnership;
}

class HomeShouldSetUpProfile extends HomeState {
  const HomeShouldSetUpProfile();
}
