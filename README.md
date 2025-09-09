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

## 🛠️ Architecture & Tech Stack

Clean architecture with feature-based organization:

**Technologies:**
- **State Management**: `flutter_bloc`
- **Navigation**: `go_router` 
- **Backend**: Firebase (Auth, Firestore, Storage, Analytics, Crashlytics)
- **Local Storage**: `hive_ce_flutter`
- **Dependency Injection**: `get_it` + `injectable`
- **AI**: `firebase_ai`

**Structure:**
```
/ - Root
  ├── lib/                    # Main app code
  │   ├── ui/                 # Features and shared widgets
  │   │   ├── features/       # Individual app features (Home, Calendar, etc.)
  │   │   └── shared_widgets/ # Reusable UI components
  │   ├── data/               # Models, repositories, and business logic services
  │   ├── app/                # Routing, theming, and configuration
  │   ├── config/             # DI, Firebase setup, Hive boxes
  │   └── utils/              # Extensions, formatters, analytics
  ├── assets/                 # Static assets like images and fonts
  │   ├── app_logo/           # App logos for different platforms
  │   └── fonts/              # Custom fonts
  ├── android/                # Android-specific code
  ├── ios/                    # iOS-specific code
  ├── web/                    # Web-specific code
  └── test/                   # Unit and widget tests
```

### 📝 License

This repository includes an MIT + Commons Clause license. See the [LICENSE](LICENSE) file for details.
