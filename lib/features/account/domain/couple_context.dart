import 'package:equatable/equatable.dart';

class CoupleMember extends Equatable {
  const CoupleMember({
    required this.userId,
    required this.displayName,
    this.profilePictureUrl,
    this.hasCycle = false,
    this.isSharingCycleWithPartner = false,
  });

  final String userId;
  final String displayName;

  // Null unless the context was resolved with profile pictures.
  final String? profilePictureUrl;

  final bool hasCycle;
  final bool isSharingCycleWithPartner;

  @override
  List<Object?> get props => [
    userId,
    displayName,
    profilePictureUrl,
    hasCycle,
    isSharingCycleWithPartner,
  ];
}

class CoupleContext extends Equatable {
  const CoupleContext({required this.me, this.partner});

  final CoupleMember me;

  // Null until there is a partnership and the partner's profile resolves.
  final CoupleMember? partner;

  @override
  List<Object?> get props => [me, partner];
}
