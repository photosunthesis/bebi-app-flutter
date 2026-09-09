class AppUpdateInfo {
  const AppUpdateInfo({
    required this.oldVersion,
    required this.newVersion,
    required this.releaseNotes,
    required this.hasUpdate,
    required this.downloadUrl,
    required this.publishedAt,
  });

  final String oldVersion;
  final String newVersion;
  final String releaseNotes;
  final bool hasUpdate;
  final String downloadUrl;
  final DateTime publishedAt;
}
