import 'dart:async';

import 'package:bebi_app/config/firebase_providers.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

mixin class AddPartnerEvent {
  Future<void> connectWithPartner(WidgetRef ref, {String? partnerCode}) async {
    final firebaseAuth = ref.read(firebaseAuthProvider);
    final firebaseAnalytics = ref.read(firebaseAnalyticsProvider);
    final userProfileRepository = ref.read(userProfileRepositoryProvider);
    final userPartnershipRepository = ref.read(
      userPartnershipsRepositoryProvider,
    );

    final existingPartnership = await userPartnershipRepository.getByUserId(
      firebaseAuth.currentUser!.uid,
    );

    if (partnerCode?.isEmpty != true) {
      // Check if someone has already used current user's code to pair
      if (existingPartnership == null) {
        throw ArgumentError('No partner found for the provided code.');
      }

      _logAddPartnerEvent(
        firebaseAnalytics,
        connectionMethod: 'user_code',
        hasExistingPartnership: true,
      );

      return;
    }

    final partnerProfile = await userProfileRepository.getByUserCode(
      partnerCode!,
    );

    if (partnerProfile == null) {
      throw ArgumentError('No partner found for the provided code.');
    }

    await userPartnershipRepository.create(
      UserPartnership(
        id: '', // Firebase will generate this
        users: [partnerProfile.userId, firebaseAuth.currentUser!.uid],
        createdBy: firebaseAuth.currentUser!.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    _logAddPartnerEvent(
      firebaseAnalytics,
      connectionMethod: 'partner_code',
      hasExistingPartnership: existingPartnership != null,
    );
  }

  void _logAddPartnerEvent(
    FirebaseAnalytics firebaseAnalytics, {
    required String connectionMethod,
    bool hasExistingPartnership = false,
  }) {
    firebaseAnalytics.logEvent(
      name: 'partner_added',
      parameters: {
        'connection_method': connectionMethod,
        'has_existing_partnership': hasExistingPartnership,
      },
    );
  }
}
