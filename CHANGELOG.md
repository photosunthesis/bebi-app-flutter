# Changelog

All notable changes to this project will be documented in this file.

## [0.6.0] - 2026-09-10

### Added

- Profile pictures: Upload one during profile setup and see it on the home and cycles screens 🖼️
- Prediction confidence: Cycle predictions and AI insights now say how sure they are 🔮

### Changed

- Cycle insights now run on a newer AI model (Gemini 3.5 Flash-Lite) 🤖
- Reworked how the app is put together under the hood, nothing should look or behave differently 🧱
- Refined the AI insights tone, including a note on intimacy around ovulation 🌸
- Polished the download and delete buttons on stories 💄
- Updated Flutter to 3.47.2 🚀

### Fixed

- Stories from a previous account no longer show up after signing out and into another one 🐛
- Profiles now refresh right after setting up cycle tracking 🩹
- The cycles and stories screens no longer crash while your profile info is still loading 🐛

## [0.5.2] - 2025-10-20

### Added

- Added button to delete stories: Users can now remove unwanted stories from their collection 🗑️
- Added button to download story images: Users can now save story images to their device 📥📸

## [0.5.1] - 2025-10-17

### Changed

- Migrated from `minio` package and local `.env` secrets to Firebase Cloud Functions for Cloudflare R2 storage for improved security 🔒☁️

## [0.5.0] - 2025-10-16

### Added

- Added Stories feature: Share moments and updates with your partner through photos and text 📸📝

### Changed

- Updated Flutter version to 3.35.6 🚀

### Fixed

- Fixed small UI issue with the "Today" button on the cycle calendar screen 🐛

## [0.4.9] - 2025-10-10

### Changed

- Updated Flutter version to 3.35.5 🚀

### Fixed

- Fixed issue when loading cycle data 🐛

## [0.4.8] - 2025-10-01

### Fixed

- Fixed AppBar not displaying properly on the profile update screen
- Fixed current user avatar not appearing on the cycles screen
- Fixed repeating calendar events not being created as expected

### Changed

- Replaced the calendar with a simple date picker for selecting dates when creating calendar events 📅

## [0.4.7] - 2025-09-24

### Changed

- Updated Flutter version to 3.35.4 🚀

## [0.4.6] - 2025-09-05

### Changed

- Removed personally identifiable information from analytics 🔒

### Fixed

- Fixed issue with creating recurring calendar events 🗓️

## [0.4.5] - 2025-09-02

### Added

- Added a LICENSE file with the MIT + Commons Clause license (see LICENSE for details)

### Changed

- Updated error messages on sign in to be friendlier and more informative 🛠️

### Fixed

- Fixed issue with cycle events being stored with incorrect dates 📅
- Fixed issue where cycle event data would not refresh after logging 🔄

## [0.4.4] - 2025-09-01

### Changed

- Minor bug fixes and performance improvements 🛠️

## [0.4.3] - 2025-09-01

### Changed

- Added Android app signing for smoother update installations 📱

## [0.4.2] - 2025-08-30

### Fixed

- Fixed more issues on web (Flutter web really sucks ass 🙄🙄)

## [0.4.1] - 2025-08-29

### Fixed

- Fixed various issues on web (Flutter web sucks ass 😓)

## [0.4.0] - 2025-08-29

### Added

- Web App Support: Access the app from any browser with full feature parity 🌐

### Changed

- Upgraded to Flutter v3.35.2
- Improved calendar events UI

## [0.3.3] - 2025-08-19

## Added

- Historical ovulation tracking: View ovulation predictions for your past cycles 🥚

## Fixed

- Fixed insights section showing the incorrect cycle phase 🔧

## [0.3.2] - 2025-08-19

### Fixed

- Fixed issue with refreshing the cycles screen 🔄

## [0.3.1] - 2025-08-19

### Fixed

- Fixed issue with logging menstrual flow data not being saved properly 🌸
- Fixed incorrect URL being used as the download URL in the app update dialog 🔗

## [0.3.0] - 2025-08-19

### Added

- Cycle Calendar: View your past cycle logs and future predictions in a calendar view 🗓️

### Changed

- Period duration calculation now uses actual cycle history instead of hardcoded 5-day default 📈
- Simplified data models by switching from freezed to regular Dart classes ✨
- Update dialog now takes you directly to the download file instead of the GitHub release page 🔗

### Fixed

- Fixed issue with the app bar height on Android devices being too small

## [0.2.4] - 2025-08-17

### Fixed

- Fixed issue with cycle data not being displayed properly 🐛

## [0.2.3] - 2025-08-17

### Added

- Feature to clean up local data when installing new app versions 🧹

### Changed

- Switched from freezed classes to good ol' dart classes 🔄

## [0.2.2] - 2025-08-16

## Fixed

- Fixed an issue where the home screen wasn't redirecting the user to the appropriate set ups. 🐛

## [0.2.1] - 2025-08-15

### Added

- Simple Home UI screen with sign out and update password buttons 🏠

### Changed

- Upgraded to Flutter 3.35 ⬆️

## [0.2.0] - 2025-08-15

### Added

- App now checks for updates and lets you grab the latest version 🔄
- Email verification to make sure your account is actually yours 📧

## [0.1.2] - 2025-08-14

### Added

- Added a way to verify your email so your account stays secure 🔒
- Started supporting different languages (just English for now, more coming soon) 🌍

## [0.1.1] - 2025-08-14

### Added

- Added usage analytics to help figure out what works and what doesn't so the app can be improved 📊

## [0.1.0] - 2025-08-13

### Added

- First version of the app is out! 🚀
- Calendar stuff so you can:
  - Add, change, and remove events 📅
  - See everything laid out in a calendar 🗓️
- Period tracking features so you can:
  - Keep tabs on your period days and symptoms 🩸
  - See predictions about your next cycles 🔮
  - Record health info related to your cycle 💊
