import 'dart:math' as math;

import 'package:injectable/injectable.dart';

@injectable
class CompareAppVersionsUsecase {
  const CompareAppVersionsUsecase();

  bool call(String remoteVersion, String currentVersion) {
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
