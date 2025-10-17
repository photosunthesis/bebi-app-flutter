import 'dart:async';

import 'package:bebi_app/data/models/async_value.dart';
import 'package:bebi_app/data/models/story.dart';
import 'package:bebi_app/data/models/user_partnership.dart';
import 'package:bebi_app/data/models/user_profile.dart';
import 'package:bebi_app/data/repositories/stories_repository.dart';
import 'package:bebi_app/data/repositories/user_partnerships_repository.dart';
import 'package:bebi_app/data/repositories/user_profile_repository.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';

part 'stories_state.dart';

@injectable
class StoriesCubit extends Cubit<StoriesState> with GuardMixin {
  StoriesCubit(
    this._firebaseAuth,
    this._storiesRepository,
    this._userProfileRepository,
    this._userPartnershipsRepository,
  ) : super(const StoriesState());

  final FirebaseAuth _firebaseAuth;
  final StoriesRepository _storiesRepository;
  final UserProfileRepository _userProfileRepository;
  final UserPartnershipsRepository _userPartnershipsRepository;

  UserPartnership? _partnership;

  Future<void> initialize({bool useCache = true}) async {
    emit(
      state.copyWith(
        stories: const AsyncLoading(),
        userProfile: const AsyncLoading(),
        partnerProfile: const AsyncLoading(),
      ),
    );

    _partnership ??= (await _userPartnershipsRepository.getByUserId(
      _firebaseAuth.currentUser!.uid,
    ))!;

    emit(
      state.copyWith(
        stories: await AsyncValue.guard(
          () async => _storiesRepository.getUserStories(
            _firebaseAuth.currentUser!.uid,
            useCache: useCache,
          ),
        ),
        userProfile: await AsyncValue.guard(
          () async =>
              _userProfileRepository.getByUserId(_partnership!.users.first),
        ),
        partnerProfile: await AsyncValue.guard(
          () async =>
              _userProfileRepository.getByUserId(_partnership!.users.last),
        ),
      ),
    );
  }

  void setCapturedImage(XFile imageFile) {
    emit(state.copyWith(captureImage: AsyncData(imageFile)));
  }

  Future<void> createStory(
    String title, {
    bool flipHorizontally = false,
  }) async {
    emit(state.copyWith(createStory: const AsyncLoading()));
    emit(
      state.copyWith(
        createStory: await AsyncValue.guard(() async {
          final imageFile = flipHorizontally
              ? XFile.fromData(
                  img.encodeJpg(
                    img.flipHorizontal(
                      img.decodeImage(
                        await state.captureImage.asData()!.readAsBytes(),
                      )!,
                    ),
                  ),
                  mimeType: 'image/jpeg',
                )
              : state.captureImage.asData()!;

          await _storiesRepository.createStory(
            createdBy: _firebaseAuth.currentUser!.uid,
            title: title,
            users: _partnership!.users,
            imageFile: imageFile,
          );

          clearCapturedImage();
          await initialize();
        }),
      ),
    );
  }

  Future<String> getStoryImageUrl(Story story) async {
    late final String url;

    await guard(
      () async {
        url = await _storiesRepository.getStoryImageUrl(story);
      },
      onError: (e, s) {
        print(e);
        url = '';
      },
    );

    return url;
  }

  void clearCapturedImage() {
    emit(state.copyWith(captureImage: const AsyncData(null)));
  }
}
