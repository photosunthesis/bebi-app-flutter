import 'package:bebi_app/constants/ui_constants.dart';
import 'package:bebi_app/ui/features/stories/stories_cubit.dart';
import 'package:bebi_app/ui/shared_widgets/snackbars/default_snackbar.dart';
import 'package:bebi_app/utils/extensions/build_context_extensions.dart';
import 'package:bebi_app/utils/extensions/int_extensions.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:bebi_app/utils/platform/platform_utils.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

class StoriesCamera extends StatefulWidget {
  const StoriesCamera({super.key});

  @override
  State<StoriesCamera> createState() => _StoriesCameraState();
}

class _StoriesCameraState extends State<StoriesCamera> with GuardMixin {
  static const _minZoom = 1.0;
  static const _maxZoom = 10.0;
  static const _ultrawideThreshold = 0.75;
  static const _ultrawideDisplayZoom = 0.5;

  final _minZooms = <int, double>{};
  final _maxZooms = <int, double>{};
  final _pendingDisposals = <CameraController>[];

  late final _cubit = context.read<StoriesCubit>();

  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  int _currentCameraIndex = 0;
  double _currentZoom = _minZoom;
  bool _useFlash = false;
  double _baseZoom = _minZoom;
  bool _captureInProgress = false;
  bool _switchingCamera = false;
  int? _primaryBackIndex;
  int? _ultrawideBackIndex;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
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
            child: _buildCameraContent(),
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

  Widget _buildCameraContent() {
    return BlocBuilder<StoriesCubit, StoriesState>(
      builder: (context, state) {
        if (state.image != null) {
          return _buildCapturedImagePreview(state.image!);
        }
        return _buildCameraPreviewOrPlaceholder();
      },
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
          onPressed: _canSwitchCamera() && !_switchingCamera
              ? _switchCamera
              : null,
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
            snapshot.hasError ||
            !snapshot.hasData) {
          return _buildCameraPlaceholder();
        }
        return SizedBox.expand(
          key: const ValueKey('captured_image'),
          child: Image.memory(snapshot.data!, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildCameraPlaceholder() {
    return ColoredBox(
      key: const ValueKey('camera_placeholder'),
      color: context.colorScheme.secondary.withAlpha(100),
      child: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }

  Widget _buildCameraPreviewWithController() {
    return GestureDetector(
      key: const ValueKey('camera_preview'),
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      child: Stack(
        fit: StackFit.expand,
        children: [_buildCameraPreview(), _buildZoomIndicator()],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController!;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize!.height,
          height: controller.value.previewSize!.width,
          child: CameraPreview(controller),
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
          '${_displayZoom.toStringAsFixed(1)}x',
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    await guard(() async {
      // Use the raw (unclamped) zoom value to decide camera switching so we
      // can detect values < 1.0 and switch to the ultrawide when appropriate.
      final rawNewZoom = _baseZoom * details.scale;

      if (_shouldSwitchToUltrawide(rawNewZoom)) {
        await _switchToUltrawideCamera();
      } else if (_shouldSwitchToPrimary(rawNewZoom)) {
        // When switching back to primary, pass the raw value so the target
        // zoom can be applied after switching. The setter will clamp it.
        await _switchToPrimaryCamera(rawNewZoom);
      } else {
        // Clamp before applying to the controller to respect device limits.
        final newZoom = rawNewZoom.clamp(_minZoom, _maxZoom);
        await _setZoomLevel(newZoom);
      }
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

      if (_cameras?.isNotEmpty == true) {
        // First camera is usually the primary back
        _primaryBackIndex = 0;

        // If there's more than one camera, assume the last is ultrawide back
        _ultrawideBackIndex = _cameras!.length > 1
            ? _cameras!.length - 1
            : null;

        _currentCameraIndex = _primaryBackIndex ?? 0;

        await _createControllerForIndex(_currentCameraIndex);
      }
      setState(() {});
    }, onError: _handleError);
  }

  Future<void> _createControllerForIndex(int index) async {
    await _disposeCurrentControllerAsync();

    final desc = _cameras![index];
    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
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
    try {
      final min = await controller.getMinZoomLevel();
      final max = await controller.getMaxZoomLevel();
      _minZooms[index] = min;
      _maxZooms[index] = max;
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (!_canSwitchCamera() || _switchingCamera) return;
    _switchingCamera = true;
    final newIndex = (_currentCameraIndex + 1) % _cameras!.length;
    await _switchToCameraIndex(newIndex);
    _switchingCamera = false;
  }

  Future<void> _switchToCameraIndex(int index) async {
    if (_cameras?.isEmpty != false) return;
    final normalized = index % _cameras!.length;
    await _createControllerForIndex(normalized);
  }

  Future<void> _switchToUltrawideCamera() async {
    if (_ultrawideBackIndex == null ||
        _currentCameraIndex == _ultrawideBackIndex) {
      return;
    }

    await _switchToCameraIndex(_ultrawideBackIndex!);
    final targetZoom = _minZooms[_ultrawideBackIndex!] ?? _ultrawideDisplayZoom;
    await _setZoomLevel(targetZoom);
  }

  Future<void> _switchToPrimaryCamera(double newZoom) async {
    if (_primaryBackIndex == null || _currentCameraIndex == _primaryBackIndex) {
      return;
    }

    await _switchToCameraIndex(_primaryBackIndex!);
    await _setZoomLevel(newZoom);
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
    try {
      await _cameraController!.setFlashMode(mode);

      if (mode == FlashMode.torch) {
        await Future.delayed(100.milliseconds);
      }

      final image = await _cameraController!.takePicture();
      await _safelySetFlashMode(_cameraController!, FlashMode.off);
      return image;
    } catch (_) {
      await _safelySetFlashMode(_cameraController!, FlashMode.off);
      return null;
    }
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
    return (_cameras?.length ?? 0) > 1;
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

  bool _shouldSwitchToUltrawide(double newZoom) {
    return newZoom <= _ultrawideThreshold &&
        _ultrawideBackIndex != null &&
        _currentCameraIndex != _ultrawideBackIndex;
  }

  bool _shouldSwitchToPrimary(double newZoom) {
    return newZoom > _ultrawideThreshold &&
        _primaryBackIndex != null &&
        _currentCameraIndex != _primaryBackIndex;
  }

  double get _displayZoom {
    if (_cameras?.isEmpty != false) return _currentZoom;

    if (_isUltrawideCamera) {
      return _calculateUltrawideDisplayZoom();
    }

    return _currentZoom;
  }

  bool get _isUltrawideCamera {
    return _ultrawideBackIndex != null &&
        _currentCameraIndex == _ultrawideBackIndex;
  }

  double _calculateUltrawideDisplayZoom() {
    // TODO Improve this calculation
    return kIsAndroid ? 0.6 : 0.5;
  }

  void _disposePendingControllers() {
    for (final controller in _pendingDisposals) {
      try {
        controller.dispose();
      } catch (_) {}
    }
    _pendingDisposals.clear();
  }

  void _disposeCurrentController() {
    try {
      _cameraController?.dispose();
    } catch (_) {}
  }

  Future<void> _safelyDisposeController(CameraController controller) async {
    try {
      await controller.setFlashMode(FlashMode.off);
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> _safelySetFlashMode(
    CameraController controller,
    FlashMode mode,
  ) async {
    try {
      await controller.setFlashMode(mode);
    } catch (_) {}
  }

  void _handleError(Object error, StackTrace stackTrace) {
    context.showSnackbar(error.toString());
  }
}
