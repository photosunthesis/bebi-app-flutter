part of 'add_partner_cubit.dart';

@freezed
abstract class AddPartnerState with _$AddPartnerState {
  const factory AddPartnerState({
    required String currentUserCode,
    @Default(false) bool loading,
    @Default(false) bool success,
    String? error,
  }) = _AddPartnerState;
}
