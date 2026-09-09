import 'package:camera/camera.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

@injectable
class ImageStorageService {
  const ImageStorageService(this._functions);

  final FirebaseFunctions _functions;

  Future<String> uploadProfilePictureFile(
    XFile imageFile, {
    String? path,
  }) async {
    final mimeType = imageFile.mimeType ?? 'image/jpeg';
    final (uploadUrl, objectName) = await _functions
        .httpsCallable('getProfilePictureUploadUrl')
        .call({'filename': imageFile.name, 'contentType': mimeType})
        .then((result) {
          final data = result.data as Map<String, dynamic>;
          return (data['uploadUrl'] as String, data['key'] as String);
        });

    await http.put(
      Uri.parse(uploadUrl),
      body: await imageFile.readAsBytes(),
      headers: {'Content-Type': mimeType},
    );

    return objectName;
  }

  Future<String> uploadStoryImageFile(XFile imageFile, {String? path}) async {
    final mimeType = imageFile.mimeType ?? 'image/jpeg';
    final (uploadUrl, objectName) = await _functions
        .httpsCallable('getStoryUploadUrl')
        .call({'filename': imageFile.name, 'contentType': mimeType})
        .then((result) {
          final data = result.data as Map<String, dynamic>;
          return (data['uploadUrl'] as String, data['key'] as String);
        });

    await http.put(
      Uri.parse(uploadUrl),
      body: await imageFile.readAsBytes(),
      headers: {'Content-Type': mimeType},
    );

    return objectName;
  }

  Future<String> getImageUrlByObjectName(String objectName) async {
    final imageUrl = await _functions
        .httpsCallable('getPresignedUrl')
        .call({'filename': objectName})
        .then(
          (result) => (result.data as Map<String, dynamic>)['url'] as String,
        );

    return imageUrl;
  }

  Future<void> deleteImageByObjectName(String objectName) async {
    await _functions.httpsCallable('deleteProfilePicture').call({
      'key': objectName,
    });
  }
}
