import 'dart:math' as math;

import 'package:bebi_app/data/models/app_update_info.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

@injectable
class AppUpdateService {
  const AppUpdateService(this._dio, this._packageInfo);

  final Dio _dio;
  final PackageInfo _packageInfo;

  static const _owner = 'photosunthesis';
  static const _repo = 'bebi-app-flutter';
  static const _baseUrl = 'https://api.github.com';

  Future<AppUpdateInfo?> checkForUpdate() async {
    final response = await _dio.get(
      '$_baseUrl/repos/$_owner/$_repo/releases/latest',
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }

    return _parseReleaseData(response.data);
  }

  AppUpdateInfo _parseReleaseData(Map<String, dynamic> releaseData) {
    final latestVersion = _extractVersion(releaseData['tag_name'] as String);
    final releaseNotes =
        releaseData['body'] as String? ?? 'No release notes available.';
    final releaseUrl = releaseData['html_url'] as String;
    final publishedAt = DateTime.parse(releaseData['published_at']);
    final hasUpdate = _isVersionNewer(latestVersion, _packageInfo.version);

    return AppUpdateInfo(
      oldVersion: _packageInfo.version,
      newVersion: latestVersion,
      releaseNotes: releaseNotes,
      hasUpdate: hasUpdate,
      releaseUrl: releaseUrl,
      publishedAt: publishedAt,
    );
  }

  String _extractVersion(String tagName) => tagName.replaceFirst('v', '');

  bool _isVersionNewer(String remoteVersion, String currentVersion) {
    try {
      final remoteParts = _parseVersionParts(remoteVersion);
      final currentParts = _parseVersionParts(currentVersion);

      final maxLength = math.max(remoteParts.length, currentParts.length);

      for (var i = 0; i < maxLength; i++) {
        final remote = i < remoteParts.length ? remoteParts[i] : 0;
        final current = i < currentParts.length ? currentParts[i] : 0;

        if (remote > current) return true;
        if (remote < current) return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  List<int> _parseVersionParts(String version) {
    return version.split('.').map((part) {
      final cleanPart = part.split('+')[0].split('-')[0];
      return int.tryParse(cleanPart) ?? 0;
    }).toList();
  }
}
