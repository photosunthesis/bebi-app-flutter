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

class HomeShouldSetUpProfile extends HomeState {
  const HomeShouldSetUpProfile();
}