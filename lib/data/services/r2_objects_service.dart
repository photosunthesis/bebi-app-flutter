import 'dart:math';

import 'package:bebi_app/config/env.dart';
import 'package:camera/camera.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
// ignore: depend_on_referenced_packages
import 'package:mime/mime.dart';
import 'package:minio/minio.dart';

@lazySingleton
class R2ObjectsService {
  R2ObjectsService(this._env)
    : _minio = Minio(
        endPoint: _env.r2Endpoint,
        accessKey: _env.r2AccessKeyId,
        secretKey: _env.r2SecretAccessKey,
      );

  final Minio _minio;
  final Env _env;

  Future<String> uploadFile(
    XFile file, {
    String? path,
    String? fileName,
  }) async {
    final timestamp = DateFormat('yyyy-MM-dd-HHmm-ss').format(DateTime.now());
    final suffix = _randomString();
    final fileExtension = extensionFromMime(
      file.mimeType ?? 'application/octet-stream',
    );
    final name = fileName ?? '$timestamp-$suffix.$fileExtension';

    // Sanitize the optional path and build the final object key
    final sanitizedPath = path?.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    final objectName = (sanitizedPath != null && sanitizedPath.isNotEmpty)
        ? '$sanitizedPath/$name'
        : name;

    await _minio.putObject(
      _env.r2BucketName,
      objectName,
      file.readAsBytes().asStream(),
    );

    return objectName;
  }

  /// Generate a fresh signed URL for a stored object.
  Future<String> getPresignedUrl(
    String objectName, {
    int? expiryInSeconds = 60 * 60, // 1 hour
  }) async {
    final url = await _minio.presignedGetObject(
      _env.r2BucketName,
      objectName,
      expires: expiryInSeconds,
    );

    return url;
  }

  String _randomString([int length = 16]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random(DateTime.now().millisecondsSinceEpoch);
    return List.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }
}
