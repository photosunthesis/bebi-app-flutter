<div align="center">
  <img src="assets/app_logo/app_logo_readme.png" alt="The Bebi App Logo" width="120" height="120" style="filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.2));">
</div>

# Bebi App

A couples app I built for me and my girlfriend to keep track of things and share moments together. Built with **Flutter**. 💙

## What it does

- 📅 **Shared Calendar**: Keep track of our dates, events, and appointments together.
- 📸 **Stories**: Share daily candid photos with each other (work-in-progress).
- 🌸 **Cycle Tracking**: Log menstruation events and symptoms, and access AI-powered insights.
- 📍 **Location Sharing**: Optionally share location with your partner when it's useful (work-in-progress).

## 🛠️ Project Structure & Tech Stack

Clean architecture with feature-based organization:

**Technologies:**
- **State Management**: `flutter_bloc`
- **Navigation**: `go_router` 
- **Backend**: Firebase (Auth, Firestore, Storage, Analytics, Crashlytics)
- **Local Storage**: `hive_ce_flutter`
- **Dependency Injection**: `get_it` + `injectable`
- **AI**: `firebase_ai`

**Project Structure:**
```
/ - Root
  ├── lib/                    # Main app code
  │   ├── main.dart           # App entrypoint
  │   ├── app/                # Routing, theming and top-level app wiring
  │   │   ├── app.dart
  │   │   └── router/         # Route definitions and helpers
  │   │   └── theme/          # Colors & ThemeData
  │   ├── config/             # DI, Firebase setup, generated configs
  │   ├── constants/          # Asset names, fonts, ids, UI constants
  │   ├── data/               # Data sources and repositories
  │   │   ├── models/         # Data models
  │   │   ├── repositories/   # Data repositories
  │   │   └── services/       # Data services
  │   ├── localizations/      # Generated/localization files
  │   ├── ui/                 # Features and shared widgets
  │   │   ├── features/       # Feature folders (calendar, stories, profile...)
  │   │   └── shared_widgets/ # Reusable UI components (forms, pickers...)
  │   └── utils/              # Extensions, formatters, platform utils
  ├── assets/                 # Static assets like images and fonts
  ├── android/                # Android-specific code
  ├── ios/                    # iOS-specific code
  ├── web/                    # Web-specific code
  └── test/                   # Tests
```

### 📝 License

This repository includes an MIT + Commons Clause license. See the [LICENSE](LICENSE) file for details.
