import 'dart:math' as math;

import 'package:bebi_app/config/utility_packages_provider.dart';
import 'package:bebi_app/data/models/app_update_info.dart';
import 'package:bebi_app/utils/mixins/localizations_mixin.dart';
import 'package:bebi_app/utils/platform/platform_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

final appUpdateServiceProvider = Provider.autoDispose(
  (ref) => AppUpdateService(ref.read(packageInfoProvider)),
);

class AppUpdateService with LocalizationsMixin {
  const AppUpdateService(this._packageInfo);

  final PackageInfo _packageInfo;

  static const _owner = 'photosunthesis';
  static const _repo = 'bebi-app-flutter';
  static const _baseUrl = 'https://api.github.com';

  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      if (kIsWeb) return null;

      final client = http.Client();
      final response = await client.get(
        Uri.parse('$_baseUrl/repos/$_owner/$_repo/releases/latest'),
      );

      if (response.statusCode != 200) throw Exception(l10n.checkUpdateError);

      return _parseReleaseData(response.body as Map<String, dynamic>);
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
    final hasUpdate = _isVersionNewer(latestVersion, _packageInfo.version);

    return AppUpdateInfo(
      oldVersion: _packageInfo.version,
      newVersion: latestVersion,
      releaseNotes: releaseNotes,
      hasUpdate: hasUpdate,
      downloadUrl: downloadUrl,
      publishedAt: publishedAt,
    );
  }

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
