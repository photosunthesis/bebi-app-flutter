import 'dart:async';
import 'dart:math' as math;

import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/stories/stories_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class StoriesCamera extends StatefulWidget {
  const StoriesCamera({super.key});

  @override
  State<StoriesCamera> createState() => _StoriesCameraState();
}

class _StoriesCameraState extends State<StoriesCamera>
    with GuardMixin, SingleTickerProviderStateMixin {
  static const _minZoom = 1.0;
  static const _maxZoom = 10.0;

  final _minZooms = <int, double>{};
  final _maxZooms = <int, double>{};
  final _pendingDisposals = <CameraController>[];

  late final _cubit = context.read<StoriesCubit>();

  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  int _currentCameraIndex = 0;
  double _currentZoom = _minZoom;
  double _baseZoom = _minZoom;
  bool _useFlash = false;
  bool _captureInProgress = false;
  bool _switchingCamera = false;
  // Tap-to-focus overlay state
  Offset? _focusOffset;
  AnimationController? _focusController;
  Timer? _focusHideTimer;
  Timer? _focusUnlockTimer;
  bool _isManualFocusActive = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _focusController = AnimationController(
      vsync: this,
      duration: 200.milliseconds,
    );

    _focusController!.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() => _focusOffset = null);
      }
    });
  }

  @override
  void dispose() {
    _focusHideTimer?.cancel();
    _focusUnlockTimer?.cancel();
    _focusController?.dispose();
    _disposePendingControllers();
    _disposeCurrentController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      decoration: _buildContainerDecoration(),
      child: ClipRRect(
        borderRadius: UiConstants.biggerBorderRadius,
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedSwitcher(
            duration: 300.milliseconds,
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: BlocBuilder<StoriesCubit, StoriesState>(
              builder: (context, state) {
                if (state.image != null) {
                  return _buildCapturedImagePreview(state.image!);
                }

                return _buildCameraPreviewOrPlaceholder();
              },
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      borderRadius: UiConstants.biggerBorderRadius,
      color: context.colorScheme.surfaceContainerHighest,
      border: Border.all(
        color: context.colorScheme.outline.withAlpha(80),
        width: UiConstants.borderWidth,
      ),
    );
  }

  Widget _buildCameraPreviewOrPlaceholder() {
    return Builder(
      key: ValueKey(_cameraController?.value.isInitialized ?? false),
      builder: (context) {
        if (!_isCameraReady()) {
          return _buildCameraPlaceholder();
        }

        return _buildCameraPreviewWithController();
      },
    );
  }

  Widget _buildCameraControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UiConstants.padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFlashButton(),
          _buildShutterButton(),
          _buildSwitchCameraButton(),
        ],
      ),
    );
  }

  Widget _buildFlashButton() {
    return BlocBuilder<StoriesCubit, StoriesState>(
      builder: (context, state) {
        if (state.image != null) {
          return const SizedBox(width: 48);
        }

        return IconButton(
          onPressed: _toggleFlash,
          icon: Icon(_useFlash ? Symbols.flash_off : Symbols.flash_on),
          iconSize: 32,
          color: context.colorScheme.onSurface,
        );
      },
    );
  }

  Widget _buildShutterButton() {
    return BlocBuilder<StoriesCubit, StoriesState>(
      builder: (context, state) {
        final hasImage = state.image != null;
        return _buildCameraShutterButton(hasImage: hasImage);
      },
    );
  }

  Widget _buildSwitchCameraButton() {
    return BlocBuilder<StoriesCubit, StoriesState>(
      builder: (context, state) {
        if (state.image != null) {
          return IconButton(
            onPressed: _clearCapturedImage,
            icon: const Icon(Symbols.refresh),
            iconSize: 32,
            color: context.colorScheme.onSurface,
          );
        }
        return IconButton(
          onPressed: _canSwitchCamera() ? _switchCamera : null,
          icon: const Icon(Symbols.flip_camera_ios),
          iconSize: 32,
          color: context.colorScheme.onSurface,
        );
      },
    );
  }

  Widget _buildCameraShutterButton({bool hasImage = false}) {
    return GestureDetector(
      onTap: hasImage ? _onUploadPressed : _takePicture,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.colorScheme.onSurface, width: 3),
          color: hasImage ? context.colorScheme.onSurface : Colors.transparent,
        ),
        child: Center(
          child: hasImage
              ? Icon(
                  Symbols.send,
                  color: context.colorScheme.onPrimary,
                  size: 30,
                )
              : Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCapturedImagePreview(XFile file) {
    return FutureBuilder(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return _buildCameraPreviewWithController();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        return SizedBox.expand(
          child: Image.memory(snapshot.data!, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildCameraPlaceholder() {
    return ColoredBox(
      color: context.colorScheme.secondary.withAlpha(100),
      child: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }

  Widget _buildCameraPreviewWithController() {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onTapDown: (details) async {
            final box = context.findRenderObject() as RenderBox;
            final offset = box.globalToLocal(details.globalPosition);
            final size = box.size;
            final dx = offset.dx / size.width;
            final dy = offset.dy / size.height;

            await guard(() async {
              // Cancel any existing timers and stop any running animations
              _focusHideTimer?.cancel();
              _focusUnlockTimer?.cancel();
              _focusController?.stop();
              _focusController?.reset();

              // If we're currently in manual focus, reset to auto first
              if (_isManualFocusActive) {
                await _cameraController?.setFocusMode(FocusMode.auto);
                await Future.delayed(100.milliseconds);
              }

              // Clear the old focus indicator immediately
              setState(() {
                _focusOffset = null;
                _isManualFocusActive = false;
              });

              // Small delay to ensure the UI updates
              await Future.delayed(1.milliseconds);

              // Set focus and exposure points
              await _cameraController?.setFocusPoint(Offset(dx, dy));
              await _cameraController?.setExposurePoint(Offset(dx, dy));
              await _cameraController?.setFocusMode(FocusMode.locked);

              // Show new focus indicator at the tapped position
              setState(() {
                _focusOffset = offset;
                _isManualFocusActive = true;
              });

              // Start the animation
              await _focusController?.forward();

              // Timer to hide the ring after 4 seconds
              _focusHideTimer = Timer(4.seconds, () async {
                if (_isManualFocusActive) {
                  await _focusController?.reverse();
                }
              });

              // Timer to unlock focus after 8 seconds total
              _focusUnlockTimer = Timer(8.seconds, () async {
                if (_isManualFocusActive) {
                  await guard(() async {
                    await _cameraController?.setFocusMode(FocusMode.auto);
                    setState(() => _isManualFocusActive = false);
                  });
                }
              });
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCameraPreview(),
              _buildFocusIndicator(),
              _buildZoomIndicator(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFocusIndicator() {
    if (_focusOffset == null || _focusController == null) {
      return const SizedBox.shrink();
    }

    final animation = CurvedAnimation(
      parent: _focusController!,
      curve: Curves.easeOut,
    );
    final scaleAnimation = Tween<double>(
      begin: 1.1,
      end: 1.0,
    ).animate(animation);

    const ringSize = 60.0;

    final left = _focusOffset!.dx - ringSize / 2;
    final top = _focusOffset!.dy - ringSize / 2;

    return Positioned(
      left: left,
      top: top,
      width: ringSize,
      height: ringSize,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: CustomPaint(
              size: const Size.square(ringSize),
              painter: _FocusRingPainter(
                ringColor: context.colorScheme.onPrimary,
                ringWidth: 2.0,
                shadowWidth: 8.0,
                shadowColor: context.colorScheme.shadow.withAlpha(10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: context.colorScheme.surface.withAlpha(220),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_currentZoom.toStringAsFixed(1)}x',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (_captureInProgress) return;
    _baseZoom = _currentZoom;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_captureInProgress) return;
    await guard(() async {
      // Apply pinch-to-zoom using base zoom and scale. Clamp using known
      // device limits (if available) or overall min/max.
      final rawNewZoom = _baseZoom * details.scale;
      final newZoom = rawNewZoom.clamp(_minZoom, _maxZoom);
      await _setZoomLevel(newZoom);
    });
  }

  void _onUploadPressed() {}

  Future<void> _clearCapturedImage() async {
    _cubit.clearCapturedImage();
    setState(() {});
  }

  Future<void> _initializeCamera() async {
    await guard(() async {
      _cameras = await availableCameras();
      _currentCameraIndex = 0;
      await _createControllerForIndex(_currentCameraIndex);
      setState(() {});
    }, onError: _handleError);
  }

  Future<void> _createControllerForIndex(int index) async {
    await _disposeCurrentControllerAsync();

    final desc = _cameras![index];

    final controller = CameraController(
      desc,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;
    await controller.initialize();

    await _configureNewController(controller, index, desc);
    setState(() {});
  }

  Future<void> _disposeCurrentControllerAsync() async {
    final oldController = _cameraController;
    if (oldController != null) {
      setState(() => _cameraController = null);
      _pendingDisposals.add(oldController);

      await Future.delayed(350.milliseconds).then((_) async {
        if (_pendingDisposals.remove(oldController)) {
          await _safelyDisposeController(oldController);
        }
      });
    }
  }

  Future<void> _configureNewController(
    CameraController controller,
    int index,
    CameraDescription desc,
  ) async {
    await _safelySetFlashMode(controller, FlashMode.off);
    await _updateZoomLimits(controller, index);

    _currentCameraIndex = index;
    _currentZoom = _minZooms[index] ?? _minZoom;

    if (_useFlash && desc.lensDirection == CameraLensDirection.back) {
      await _safelySetFlashMode(controller, FlashMode.torch);
    }
  }

  Future<void> _updateZoomLimits(CameraController controller, int index) async {
    final min = await controller.getMinZoomLevel();
    final max = await controller.getMaxZoomLevel();
    _minZooms[index] = min;
    _maxZooms[index] = max;
  }

  Future<void> _switchCamera() async {
    if (!_canSwitchCamera() || _switchingCamera) return;
    _switchingCamera = true;

    if (_cameras == null || _cameras!.length < 2) {
      _switchingCamera = false;
      return;
    }

    await _createControllerForIndex(_currentCameraIndex == 0 ? 1 : 0);
    _switchingCamera = false;
  }

  Future<void> _setZoomLevel(double zoom) async {
    if (_cameraController == null) return;

    final min = _minZooms[_currentCameraIndex] ?? _minZoom;
    final max = _maxZooms[_currentCameraIndex] ?? _maxZoom;
    final clampedZoom = zoom.clamp(min, max);

    await _cameraController!.setZoomLevel(clampedZoom);
    _currentZoom = clampedZoom;
    setState(() {});
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    _useFlash = !_useFlash;

    if (_isBackCamera()) {
      final mode = _useFlash ? FlashMode.always : FlashMode.off;
      await _safelySetFlashMode(_cameraController!, mode);
    }

    setState(() {});
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady()) return;

    if (_captureInProgress) return;
    _captureInProgress = true;

    await guard(() async {
      final image = await _captureImage();
      await _cubit.setCapturedImage(image, flipHorizontally: !_isBackCamera());
      setState(() {});
    }, onError: _handleError);

    _captureInProgress = false;
  }

  Future<XFile> _captureImage() async {
    if (_shouldUseFrontFlash()) {
      return await _captureWithFrontFlash();
    }

    return await _cameraController!.takePicture();
  }

  Future<XFile> _captureWithFrontFlash() async {
    final image = await _tryFlashMode(FlashMode.torch);
    if (image != null) return image;

    final autoImage = await _tryFlashMode(FlashMode.auto);
    if (autoImage != null) return autoImage;

    return await _captureWithScreenFlash();
  }

  Future<XFile?> _tryFlashMode(FlashMode mode) async {
    await _cameraController!.setFlashMode(mode);

    if (mode == FlashMode.torch) {
      await Future.delayed(100.milliseconds);
    }

    final image = await _cameraController!.takePicture();
    await _safelySetFlashMode(_cameraController!, FlashMode.off);
    return image;
  }

  Future<XFile> _captureWithScreenFlash() async {
    await _showScreenFlash();
    return await _cameraController!.takePicture();
  }

  Future<void> _showScreenFlash() async {
    final overlay = OverlayEntry(
      builder: (context) =>
          Container(color: Colors.white, child: const SizedBox.expand()),
    );

    Overlay.of(context).insert(overlay);
    await Future.delayed(150.milliseconds);
    overlay.remove();
  }

  bool _isCameraReady() {
    return _cameraController?.value.isInitialized == true;
  }

  bool _canSwitchCamera() {
    return (_cameras?.length ?? 0) > 1 &&
        !_switchingCamera &&
        !_captureInProgress;
  }

  bool _isBackCamera() {
    return _cameraController?.description.lensDirection ==
        CameraLensDirection.back;
  }

  bool _shouldUseFrontFlash() {
    return _useFlash &&
        _cameraController!.description.lensDirection ==
            CameraLensDirection.front;
  }

  void _disposePendingControllers() {
    for (final controller in _pendingDisposals) {
      controller.dispose();
    }

    _pendingDisposals.clear();
  }

  void _disposeCurrentController() {
    _cameraController?.dispose();
  }

  Future<void> _safelyDisposeController(CameraController controller) async {
    await controller.setFlashMode(FlashMode.off);
    await controller.dispose();
  }

  Future<void> _safelySetFlashMode(
    CameraController controller,
    FlashMode mode,
  ) async {
    await controller.setFlashMode(mode);
  }

  void _handleError(Object error, StackTrace stackTrace) {
    context.showSnackbar(error.toString());
  }
}

class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({
    required this.ringColor,
    required this.ringWidth,
    required this.shadowWidth,
    required this.shadowColor,
  });

  final Color ringColor;
  final double ringWidth;
  final double shadowWidth;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - ringWidth) / 2;

    // Shadow stroke (blurred stroked circle) to create a ring-shaped shadow.
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth + shadowWidth
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowWidth);

    canvas.drawCircle(center, radius, shadowPaint);

    // Foreground ring stroke
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..color = ringColor;

    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter oldDelegate) {
    return oldDelegate.ringColor != ringColor ||
        oldDelegate.ringWidth != ringWidth ||
        oldDelegate.shadowWidth != shadowWidth ||
        oldDelegate.shadowColor != shadowColor;
  }
}
