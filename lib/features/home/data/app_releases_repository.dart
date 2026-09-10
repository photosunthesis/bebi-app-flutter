import 'dart:convert';

import 'package:bebi_app/features/home/domain/app_update_info.dart';
import 'package:bebi_app/features/home/domain/compare_app_versions_usecase.dart';
import 'package:bebi_app/utils/platform/platform_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

@injectable
class AppReleasesRepository {
  const AppReleasesRepository(this._packageInfo, this._compareAppVersions);

  final PackageInfo _packageInfo;
  final CompareAppVersionsUsecase _compareAppVersions;

  static const _owner = 'photosunthesis';
  static const _repo = 'bebi-app-flutter';
  static const _baseUrl = 'https://api.github.com';

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      if (kIsWeb) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/repos/$_owner/$_repo/releases/latest'),
      );

      if (response.statusCode != 200) return null;

      final releaseJson = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseReleaseData(releaseJson);
    } catch (_) {
      // On error we simply just not do anything 🤠
      return null;
    }
  }

  AppUpdateInfo _parseReleaseData(Map<String, dynamic> releaseData) {
    final latestVersion = releaseData['tag_name'].replaceFirst('v', '');
    final rawReleaseNotes =
        releaseData['body'] as String? ?? 'No release notes available.';
    final releaseNotes = rawReleaseNotes.split('---')[0].trim();
    final assets = releaseData['assets'] as List<dynamic>;
    final downloadUrl = kIsAndroid
        ? assets.firstWhere(
                (asset) => asset['name'] == 'android_modern_devices.apk',
              )['browser_download_url']
              as String
        : assets.firstWhere(
                (asset) => asset['name'] == 'ios.ipa',
              )['browser_download_url']
              as String;
    final publishedAt = DateTime.parse(releaseData['published_at']);
    final hasUpdate = _compareAppVersions(latestVersion, _packageInfo.version);

    return AppUpdateInfo(
      oldVersion: _packageInfo.version,
      newVersion: latestVersion,
      releaseNotes: releaseNotes,
      hasUpdate: hasUpdate,
      downloadUrl: downloadUrl,
      publishedAt: publishedAt,
    );
  }
}
