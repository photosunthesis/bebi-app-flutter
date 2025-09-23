import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bebi_app/data/models/async_value.dart';
import 'package:bebi_app/data/models/story.dart';
import 'package:bebi_app/utils/mixins/guard_mixin.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'stories_state.dart';

@injectable
class StoriesCubit extends Cubit<StoriesState> with GuardMixin {
  StoriesCubit() : super(const StoriesState());

  Future<void> initialize() async {
    await _loadStories();
  }

  Future<void> _loadStories() async {
    emit(state.copyWith(stories: const AsyncLoading()));

    final asyncStories = await AsyncValue.guard(() async {
      final fakeStories = List.generate(
        5,
        (index) => Story(
          id: 'story_$index',
          title: 'A beautiful day ${index + 1}',
          photoUrl: 'https://picsum.photos/600/600?random=${index + 1}',
          createdBy: 'user_1',
          users: ['user_1', 'user_2'],
          blurHash: 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
          createdAt: DateTime.now().subtract(Duration(days: index)),
        ),
      );

      return fakeStories;
    });

    emit(state.copyWith(stories: asyncStories));
  }

  Future<void> setCapturedImage(
    XFile file, {
    bool flipHorizontally = false,
  }) async {
    try {
      final bytes = await file.readAsBytes();

      if (!flipHorizontally) {
        emit(state.copyWith(image: file));
        return;
      }

      final decoded = await _decodeImage(bytes);

      // Draw flipped image onto a canvas
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint();
      final width = decoded.width.toDouble();

      // flip horizontally: translate by width then scale x by -1
      canvas.translate(width, 0);
      canvas.scale(-1, 1);
      canvas.drawImage(decoded, ui.Offset.zero, paint);

      final picture = recorder.endRecording();
      final flippedImage = await picture.toImage(decoded.width, decoded.height);

      final byteData = await flippedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        emit(state.copyWith(image: file));
        return;
      }

      final outBytes = byteData.buffer.asUint8List();

      // Use system temp directory (no path_provider)
      final tempDir = Directory.systemTemp;
      final fileName = 'captured_${DateTime.now().millisecondsSinceEpoch}.png';
      final outFile = File('${tempDir.path}/$fileName');
      await outFile.writeAsBytes(outBytes);

      final flippedXFile = XFile(outFile.path);

      emit(state.copyWith(image: flippedXFile));
    } catch (e, _) {
      emit(state.copyWith(image: file));
    }
  }

  Future<ui.Image> _decodeImage(Uint8List data) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(data, (img) {
      completer.complete(img);
    });
    return completer.future;
  }

  void clearCapturedImage() {
    // ignore: avoid_redundant_argument_values
    emit(state.copyWith(image: null, imageChanged: true));
  }
}
