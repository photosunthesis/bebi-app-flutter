import 'package:equatable/equatable.dart';

class SharingAudience extends Equatable {
  const SharingAudience({
    required this.users,
    required this.ownedBy,
    this.isSharingCycleWithPartner = false,
  });

  final List<String> users;
  final String ownedBy;

  // The couple's cycle sharing setting. Only meaningful on audiences resolved
  // from a cycle flow, false everywhere else.
  final bool isSharingCycleWithPartner;

  @override
  List<Object?> get props => [users, ownedBy, isSharingCycleWithPartner];
}
