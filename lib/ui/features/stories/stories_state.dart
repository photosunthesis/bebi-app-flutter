part of 'stories_cubit.dart';

class StoriesState extends Equatable {
  const StoriesState({
    this.stories = const AsyncData(<Story>[]),
    this.loadingStories = false,
    this.image,
    this.errorMessage,
  });

  final bool loadingStories;
  final AsyncValue<List<Story>> stories;
  final XFile? image;
  final String? errorMessage;

  @override
  List<Object?> get props => [stories, loadingStories, image, errorMessage];

  StoriesState copyWith({
    AsyncValue<List<Story>>? stories,
    bool? loadingStories,
    XFile? image,
    bool imageChanged = false,
    String? errorMessage,
    bool errorMessageChanged = false,
  }) {
    return StoriesState(
      stories: stories ?? this.stories,
      loadingStories: loadingStories ?? this.loadingStories,
      image: imageChanged ? image : image ?? this.image,
      errorMessage: errorMessageChanged
          ? errorMessage
          : errorMessage ?? this.errorMessage,
    );
  }
}
