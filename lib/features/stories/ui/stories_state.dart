part of 'stories_cubit.dart';

class StoriesState extends Equatable {
  const StoriesState({
    this.stories = const AsyncData(<Story>[]),
    this.createStory = const AsyncData(null),
    this.captureImage = const AsyncData(null),
  });

  final AsyncValue<List<Story>> stories;
  final AsyncValue<void> createStory;
  final AsyncValue<XFile?> captureImage;

  // TODO Add better error messages
  String? get errorMessage => stories is AsyncError
      ? (stories as AsyncError).error.toString()
      : createStory is AsyncError
      ? (createStory as AsyncError).error.toString()
      : (captureImage is AsyncError
            ? (captureImage as AsyncError).error.toString()
            : null);

  @override
  List<Object?> get props => [stories, captureImage, createStory];

  StoriesState copyWith({
    AsyncValue<List<Story>>? stories,
    AsyncValue<XFile?>? captureImage,
    AsyncValue<void>? createStory,
  }) {
    return StoriesState(
      stories: stories ?? this.stories,
      captureImage: captureImage ?? this.captureImage,
      createStory: createStory ?? this.createStory,
    );
  }
}
