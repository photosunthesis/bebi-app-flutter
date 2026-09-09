part of 'add_partner_cubit.dart';

sealed class AddPartnerState {
  const AddPartnerState();
}

class AddPartnerLoadingState extends AddPartnerState {
  const AddPartnerLoadingState();
}

class AddPartnerLoadedState extends AddPartnerState {
  const AddPartnerLoadedState(this.currentUserCode);
  final String currentUserCode;
}

class AddPartnerSuccessState extends AddPartnerState {
  const AddPartnerSuccessState();
}

class AddPartnerErrorState extends AddPartnerState {
  const AddPartnerErrorState(this.error);
  final String error;
}
