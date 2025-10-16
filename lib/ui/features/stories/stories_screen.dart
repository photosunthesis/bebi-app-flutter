import 'package:bebi_app/constants/kaomojis.dart';
import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/story.dart';
import 'package:bebi_app/ui/features/stories/components/stories_camera.dart';
import 'package:bebi_app/ui/features/stories/stories_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/datetime_extensions.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:blurhash_ffi/blurhashffi_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility_temp_fork/flutter_keyboard_visibility_temp_fork.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> with GuardMixin {
  static final _kaomoji = Kaomojis.getRandomFromHappySet();
  final _pageController = PageController();
  int _previousStoriesLength = 0;
  bool _didInitialize = false;

  @override
  void initState() {
    super.initState();
    context.read<StoriesCubit>().initialize(useCache: false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      dismissOnCapturedTaps: true,
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: BlocConsumer<StoriesCubit, StoriesState>(
          listener: _listener,
          builder: (context, state) {
            final stories = state.stories.asData() ?? [];

            return RefreshIndicator.adaptive(
              onRefresh: () async =>
                  context.read<StoriesCubit>().initialize(useCache: false),
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                // +1 for camera, +1 for empty placeholder if no stories
                itemCount: stories.length + 1 + (stories.isEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) return const StoriesCamera();
                  if (stories.isEmpty) return _buildEmptyPlaceholder(context);
                  return _buildImageCard(context, stories[index - 1]);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _listener(BuildContext context, StoriesState state) {
    if (!_didInitialize &&
        state.stories.asData() != null &&
        !state.stories.isLoading) {
      // Initialize previous stories length so we don't auto-scroll on first load
      final initial = state.stories.asData();
      _previousStoriesLength = initial?.length ?? 0;
      _didInitialize = true;

      return;
    }

    if (state.errorMessage != null) {
      context.showSnackbar(state.errorMessage!);
    }

    // When stories are refreshed and the list grows, jump to the newest
    final stories = state.stories.asData();
    final currentLength = stories?.length ?? 0;

    // If the list increased compared to previous, animate to page 1
    if (currentLength > _previousStoriesLength) {
      // page 0 is camera, page 1 is the newest story
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }

    _previousStoriesLength = currentLength;
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _kaomoji,
            style: context.textTheme.titleLarge?.copyWith(
              color: context.colorScheme.secondary.withAlpha(80),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No stories yet',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.secondary.withAlpha(80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, Story story) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(UiConstants.padding),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          color: context.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: context.colorScheme.outline.withAlpha(80),
            width: UiConstants.borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: UiConstants.biggerBorderRadius,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildStoryImage(story),
                _buildStoryDateOverlay(story),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryImage(Story story) {
    return FutureBuilder<String?>(
      future: story.getPhotoUrl(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return SizedBox.expand(
            child: Image(
              image: BlurhashFfiImage(story.blurHash),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return SizedBox.expand(
            child: Image(
              image: BlurhashFfiImage(story.blurHash),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          );
        }

        return CachedNetworkImage(
          imageUrl: snapshot.data!,
          fit: BoxFit.cover,
          placeholder: (context, url) => SizedBox.expand(
            child: Image(
              image: BlurhashFfiImage(story.blurHash),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          errorWidget: (context, url, error) => SizedBox.expand(
            child: Image(
              image: BlurhashFfiImage(story.blurHash),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoryDateOverlay(Story story) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.colorScheme.surface.withAlpha(230),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          story.createdAt.toMMMMd(),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
