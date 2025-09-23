import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/async_value.dart';
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

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> with GuardMixin {
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    context.read<StoriesCubit>().initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: BlocListener<StoriesCubit, StoriesState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            context.showSnackbar(state.errorMessage!);
          }
        },
        child:
            BlocSelector<StoriesCubit, StoriesState, AsyncValue<List<Story>>>(
              selector: (s) => s.stories,
              builder: (context, storiesData) {
                return storiesData.map(
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  data: (stories) {
                    return PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: stories.length + 1, // +1 for camera viewfinder
                      itemBuilder: (context, index) {
                        return index == 0
                            ? const StoriesCamera()
                            : _buildImageCard(context, stories[index - 1]);
                      },
                    );
                  },
                  error: (error, _) => Center(child: Text(error.toString())),
                );
              },
            ),
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
                CachedNetworkImage(
                  imageUrl: story.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => SizedBox.expand(
                    child: Image(
                      image: BlurhashFfiImage(story.blurHash),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
