import 'dart:async';

import 'package:bebi_app/data/models/app_update_info.dart';
import 'package:bebi_app/data/models/calendar_event.dart';
import 'package:bebi_app/data/models/cycle_log.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/data/services/app_update_service.dart';
import 'package:bebi_app/utils/analytics_utils.dart';
import 'package:bebi_app/utils/guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

part 'home_cubit.freezed.dart';
part 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._userProfileRepository,
    this._userPartnershipsRepository,
    this._firebaseAuth,
    this._calendarEventBox,
    this._cycleLogBox,
    this._userProfileBox,
    this._userPartnershipBox,
    this._aiSummaryAndInsightsBox,
    this._appUpdateService,
  ) : super(const HomeInitial());

  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;
  final FirebaseAuth _firebaseAuth;
  final Box<CalendarEvent> _calendarEventBox;
  final Box<CycleLog> _cycleLogBox;
  final Box<UserProfile> _userProfileBox;
  final Box<UserPartnership> _userPartnershipBox;
  final Box<String> _aiSummaryAndInsightsBox;
  final AppUpdateService _appUpdateService;

  Future<void> initialize() async {
    await guard(
      () async {
        emit(const HomeState.loading());

        if (_firebaseAuth.currentUser?.emailVerified != true) {
          emit(const HomeState.shouldConfirmEmail());
          logEvent(
            name: 'user_redirected_to_confirm_email',
            parameters: {'user_id': _firebaseAuth.currentUser!.uid},
          );
          return;
        }

        final userProfile = await _userProfileRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        if (userProfile == null) {
          emit(const HomeState.shouldSetUpProfile());
          logEvent(
            name: 'user_redirected_to_profile_setup',
            parameters: {'userId': _firebaseAuth.currentUser!.uid},
          );
          return;
        }

        final userPartnership = await _userPartnershipsRepository.getByUserId(
          _firebaseAuth.currentUser!.uid,
        );

        if (userPartnership == null) {
          emit(const HomeState.shouldAddPartner());
          logEvent(
            name: 'user_redirected_to_add_partner',
            parameters: {'user_id': _firebaseAuth.currentUser!.uid},
          );
          return;
        }

        final updateInfo = await _appUpdateService.checkForUpdate();

        if (updateInfo?.hasUpdate == true) {
          emit(HomeState.shouldUpdateApp(updateInfo!));
          logEvent(
            name: 'user_redirected_to_update_app',
            parameters: {
              'user_id': _firebaseAuth.currentUser!.uid,
              'old_version': updateInfo.oldVersion,
              'new_version': updateInfo.newVersion,
            },
          );
          return;
        }

        emit(HomeState.loaded(currentUser: userProfile));

        logEvent(
          name: 'home_screen_loaded',
          parameters: {
            'user_id': _firebaseAuth.currentUser!.uid,
            'has_partner': true,
            'has_cycle': userProfile.hasCycle,
          },
        );
      },
      onError: (error, _) {
        emit(HomeState.error(error.toString()));
      },
    );
  }

  Future<void> signOut() async {
    await guard(
      () async {
        emit(const HomeState.loading());

        logEvent(
          name: 'user_signed_out',
          parameters: {'userId': _firebaseAuth.currentUser!.uid},
        );

        await Future.wait([
          _firebaseAuth.signOut(),
          _calendarEventBox.clear(),
          _cycleLogBox.clear(),
          _userProfileBox.clear(),
          _userPartnershipBox.clear(),
          _aiSummaryAndInsightsBox.clear(),
        ]);

        emit(const HomeState.initial());
      },
      onError: (error, _) {
        emit(HomeState.error(error.toString()));
      },
    );
  }
}
