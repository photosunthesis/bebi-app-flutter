part of 'add_partner_cubit.dart';

class AddPartnerState {
  const AddPartnerState({
    required this.currentUserCode,
    this.loading = false,
    this.success = false,
    this.error,
  });

  final String currentUserCode;
  final bool loading;
  final bool success;
  final String? error;

  AddPartnerState copyWith({
    String? currentUserCode,
    bool? loading,
    bool? success,
    String? error,
    bool errorChanged = false,
  }) {
    return AddPartnerState(
      currentUserCode: currentUserCode ?? this.currentUserCode,
      loading: loading ?? this.loading,
      success: success ?? this.success,
      error: errorChanged ? error : this.error,
    );
  }
}
