import 'dart:async';

import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/data/models/async_value.dart';
import 'package:bebi_app/ui/features/stories/stories_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:camera/camera.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class StoriesCamera extends StatefulWidget {
  const StoriesCamera({super.key});

  @override
  State<StoriesCamera> createState() => _StoriesCameraState();
}

class _StoriesCameraState extends State<StoriesCamera>
    with GuardMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final _cubit = context.read<StoriesCubit>();
  final _titleController = TextEditingController();
  double _titleFieldWidth = 110.0;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _usingFlash = false;
  bool _processingImage = false;
  bool _cameraIsLoading = true;

  bool get _isBackCamera {
    return _cameraController?.description.lensDirection ==
        CameraLensDirection.back;
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateTitleFieldWidth);
    _initializeCamera();
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateTitleFieldWidth);
    _titleController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _updateTitleFieldWidth() {
    if (!mounted) return;

    final text = _titleController.text.isEmpty
        ? 'Add message'
        : _titleController.text;
    final style =
        context.textTheme.bodyLarge?.copyWith(
          color: context.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ) ??
        const TextStyle(fontSize: 16);

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    );

    // Limit measurement to a reasonable max (80% of screen)
    final maxWidth = MediaQuery.of(context).size.width * 0.8;
    tp.layout(maxWidth: maxWidth);

    // Add horizontal padding from the TextField decoration (contentPadding) and a small buffer
    const horizontalPadding = 12.0 * 2; // left + right
    final newWidth = (tp.width + horizontalPadding + 8).clamp(80.0, maxWidth);

    if ((newWidth - _titleFieldWidth).abs() > 1.0) {
      setState(() => _titleFieldWidth = newWidth);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCameraContainer(),
          const SizedBox(height: 20),
          _buildCameraControls(),
        ],
      ),
    );
  }

  Widget _buildCameraContainer() {
    return Container(
      margin: const EdgeInsets.all(UiConstants.padding),
      decoration: BoxDecoration(
        borderRadius: UiConstants.biggerBorderRadius,
        color: context.colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: context.colorScheme.outline.withAlpha(80),
          width: UiConstants.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: UiConstants.biggerBorderRadius,
        child: AspectRatio(
          aspectRatio: 1,
          child: BlocSelector<StoriesCubit, StoriesState, XFile?>(
            selector: (state) => state.captureImage.asData(),
            builder: (context, imageFile) {
              return AnimatedSwitcher(
                duration: 150.milliseconds,
                child: imageFile != null
                    ? _buildCapturedImagePreview(imageFile)
                    : _buildCameraPreviewOrPlaceholder(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreviewOrPlaceholder() {
    return AnimatedSwitcher(
      duration: 300.milliseconds,
      child: _cameraIsLoading
          ? _buildCameraPlaceholder()
          : _buildCameraPreview(),
    );
  }

  Widget _buildCameraControls() {
    return BlocSelector<StoriesCubit, StoriesState, AsyncValue<XFile?>>(
      selector: (state) => state.captureImage,
      builder: (context, captureImage) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFlashButton(captureImage.asData() != null),
              _buildMainButton(captureImage),
              _buildRefreshOrSwitchCameraButton(captureImage.asData() != null),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlashButton(bool didCaptureImage) {
    if (didCaptureImage) return const SizedBox(width: 48);

    return IconButton(
      onPressed: () => setState(() => _usingFlash = !_usingFlash),
      icon: Icon(_usingFlash ? Symbols.flash_on : Symbols.flash_off),
      iconSize: 32,
      color: context.colorScheme.onSurface,
    );
  }

  Widget _buildMainButton(AsyncValue<XFile?> captureImage) {
    final didCaptureImage = captureImage.asData() != null;
    return GestureDetector(
      onTap: _processingImage
          ? null // if capturing image, disable button
          : didCaptureImage
          ? _createStory // Upload story if user did capture image
          : _takePicture, // Otherwise, take picture
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.colorScheme.primary, width: 3),
          color: didCaptureImage || _processingImage
              ? context.colorScheme.primary
              : Colors.transparent,
        ),
        child: Center(
          // Show loading indicator if capturing image or uploading
          child: _processingImage || captureImage.isLoading
              ? SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(
                        // use onPrimary so it contrasts with the button background
                        context.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                )
              : didCaptureImage // Show send icon if image captured
              ? Icon(
                  Symbols.send,
                  color: context.colorScheme.onPrimary,
                  size: 30,
                )
              // Otherwise, show empty circle
              : Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colorScheme.primary,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRefreshOrSwitchCameraButton(bool didCaptureImage) {
    if (didCaptureImage) {
      return IconButton(
        onPressed: _processingImage
            ? null
            : () {
                _titleController.clear();
                _cubit.clearCapturedImage();
                _cameraController?.resumePreview();
              },
        icon: const Icon(Symbols.refresh),
        iconSize: 32,
        color: context.colorScheme.onSurface,
      );
    }

    return IconButton(
      onPressed: _cameras.length > 1 && !_processingImage
          ? _switchCamera
          : null,
      icon: const Icon(Symbols.flip_camera_ios),
      iconSize: 32,
      color: context.colorScheme.onSurface,
    );
  }

  Widget _buildCapturedImagePreview(XFile imageFile) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _isBackCamera
              ? Image(image: XFileImage(imageFile), fit: BoxFit.cover)
              : Transform.flip(
                  flipX: true,
                  child: Image(image: XFileImage(imageFile), fit: BoxFit.cover),
                ),
          _buildStoryTitleTextBox(),
        ],
      ),
    );
  }

  Widget _buildStoryTitleTextBox() {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: _titleFieldWidth,
          child: TextField(
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 6,
              ),
              filled: true,
              fillColor: context.colorScheme.surface.withAlpha(180),
              hintText: 'Add message',
              hintStyle: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurface.withAlpha(140),
              ),
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              counterText: '',
            ),
            controller: _titleController,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: context.colorScheme.onSurface,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return ColoredBox(
      color: context.colorScheme.secondary.withAlpha(100),
      child: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize!.height,
              height: _cameraController!.value.previewSize!.width,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createStory() async {
    if (_cubit.state.captureImage.asData() == null) return;

    await guard(
      () async {
        setState(() => _processingImage = true);

        final title = _titleController.text.trim();
        await _cubit.createStory(title, flipHorizontally: !_isBackCamera);

        // Clear the captured image and title locally so UI resets
        _titleController.clear();
        _cubit.clearCapturedImage();

        // Refresh stories list (no cache) so the new story appears in the feed
        await _cubit.initialize(useCache: false);

        // Resume camera preview so it doesn't stay frozen
        await _cameraController?.resumePreview();
      },
      onError: (error, stackTrace) {
        // Errors are already handled by cubit/listener; ensure preview resumes
        _cameraController?.resumePreview();
      },
      onComplete: () {
        setState(() => _processingImage = false);
      },
    );
  }

  Future<void> _initializeCamera() async {
    await guard(() async {
      setState(() => _cameraIsLoading = true);

      _cameras = await availableCameras().then((cameras) {
        // Filter out ultra-wide cameras first.
        final filtered = cameras
            .where((e) => e.lensType != CameraLensType.ultraWide)
            .toList();

        final front = filtered.firstWhereOrNull(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        final back = filtered.firstWhereOrNull(
          (c) => c.lensDirection == CameraLensDirection.back,
        );

        // Prefer returning front then back if both exist, otherwise fall back to what we have.
        if (front != null && back != null) return [front, back];
        if (front != null) return [front];
        if (back != null) return [back];
        return filtered;
      });

      _cameraController = CameraController(
        _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        ),
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );

      await _cameraController?.initialize();
      await _cameraController?.setFlashMode(FlashMode.off);

      setState(() => _cameraIsLoading = false);
    }, onError: (e, _) => context.showSnackbar(e.toString()));
  }

  Future<void> _switchCamera() async {
    await guard(() async {
      setState(() => _cameraIsLoading = true);

      if (_cameras.isEmpty || _cameras.length == 1) {
        setState(() => _cameraIsLoading = false);
        return;
      }

      final current = _cameraController?.description;

      // Try to toggle lens direction (front <-> back). If no camera exists
      // with the opposite lens, fall back to the next camera by index.
      CameraDescription newCamera;

      if (current != null) {
        final desired = current.lensDirection == CameraLensDirection.front
            ? CameraLensDirection.back
            : CameraLensDirection.front;

        try {
          newCamera = _cameras.firstWhere((c) => c.lensDirection == desired);
        } catch (_) {
          final currentIndex = _cameras.indexWhere(
            (c) => c.name == current.name,
          );
          final newIndex = currentIndex >= 0
              ? (currentIndex + 1) % _cameras.length
              : 0;
          newCamera = _cameras[newIndex];
        }
      } else {
        newCamera = _cameras.first;
      }

      await _cameraController?.dispose();

      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );

      await _cameraController?.initialize();
      await _cameraController?.setFlashMode(FlashMode.off);

      setState(() => _cameraIsLoading = false);
    }, onError: (e, _) => context.showSnackbar(e.toString()));
  }

  Future<void> _takePicture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _processingImage) {
      return;
    }

    setState(() => _processingImage = true);

    await guard(
      () async {
        late final XFile image;

        final useFlash = _usingFlash;

        if (useFlash) {
          await _cameraController!.setFlashMode(FlashMode.always);
        }

        image = await _cameraController!.takePicture();

        if (useFlash) {
          await _cameraController!.setFlashMode(FlashMode.off);
        }

        _cubit.setCapturedImage(image);

        await _cameraController!.pausePreview();
      },
      onError: (e, _) {
        context.showSnackbar(e.toString());
      },
    );

    setState(() => _processingImage = false);
  }
}
