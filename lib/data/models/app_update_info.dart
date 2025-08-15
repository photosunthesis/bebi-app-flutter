class AppUpdateInfo {
  const AppUpdateInfo({
    required this.oldVersion,
    required this.newVersion,
    required this.releaseNotes,
    required this.hasUpdate,
    required this.releaseUrl,
    required this.publishedAt,
  });

  final String oldVersion;
  final String newVersion;
  final String releaseNotes;
  final bool hasUpdate;
  final String releaseUrl;
  final DateTime publishedAt;
}
