<div align="center">
  <img src="assets/app_logo/app_logo_readme.png" alt="The Bebi App Logo" width="120" height="120" style="filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.2));">
</div>

An app I made for me and my girlfriend to keep track of stuff and share moments together. Built with **Flutter**. 💙

## What we use it for

- 📅 **Shared Calendar**: Keep track of important dates and events together
- 📸 **Stories**: Daily photo dumps of random stuff (🚧 WIP)
- 🌸 **Cycle Tracking**: Track periods and symptoms with AI-generated insights
- 📍 **Location Sharing**: See where the other person is when needed (🚧 WIP)

More features coming soon-ish (depending on what else we'll need from this app)

## Architecture

Built with Flutter and Firebase, using BLoC for state management and dependency injection via `get_it` + `injectable`. The AI insights are powered by Gemini through the `firebase_ai` package. Notable Firebase packages used include `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `firebase_storage`, `firebase_analytics`, and `firebase_crashlytics`. Media and large uploads (photos/videos) are stored in Cloudflare R2. Other notable packages include `go_router` for navigation, `hive` for local storage, and `super_editor` for rich text editing.

The code is organized feature-first, then layered inside each feature. The layering comes mostly from the [Flutter app architecture guide](https://docs.flutter.dev/app-architecture/guide), tweaked to how I think Flutter apps should be built after making a few of them. Every feature owns its own `ui/`, `domain/` and `data/` folders instead of the whole app sharing one big `ui/` and one big `data/`, and I've found that a lot easier to manage, maintain and work with.

```
                              features/<feature>/
       one of these per feature: account, calendar, cycles, home, stories
┌──────────────────────────────────────────────────────────────────────────────┐
│ ui/                                                                          │
│                                                                              │
│    ┌───────────────┐ user action ┌───────────────┐                           │
│    │    Screen     │ ──────────▶ │     Cubit     │                           │
│    │               │ ◀────────── │    + State    │                           │
│    └───────────────┘  new state  └───────┬───────┘                           │
│                                          ▲                                   │
│                                          ├─── domain logic ───┐              │
│                         plain read/write │                    │              │
├──────────────────────────────────────────┼────────────────────┼──────────────┤
│ domain/                                  │                    │              │
│                                          │                    │              │
│    ┌───────────────┐                     │            ┌───────────────┐      │
│    │   Entities    │                     │     ┌─────▶│   Use case    │      │
│    │  plain Dart   │                     │     │      │               │      │
│    └───────────────┘                     │     │      └───────┬───────┘      │
│                                          │     │              ▲              │
├──────────────────────────────────────────┼─────┼──────────────┼──────────────┤
│ data/                                    │     │              │              │
│                                          │     ▼              ▼              │
│    ┌───────────────┐             ┌───────────────┐    ┌───────────────┐      │
│    │      DTO      │ ◀─────────▶ │ Repository A  │    │ Repository B  │      │
│    │ Hive adapter  │             │               │    │               │      │
│    └───────────────┘             └───────┬───────┘    └───────┬───────┘      │
│                                          ▲                    ▲              │
│                                          │                    │              │
└──────────────────────────────────────────┼────────────────────┼──────────────┘
                                           │                    │           
                                           ▼                    ▼           
┌──────────────────────────────────────────────────────────────────────────────┐
│ data sources                                                                 │
│                                                                              │
│     Firestore · Hive · Cloud Functions · Cloudflare R2 · Gemini · GitHub     │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

Inside a feature, the screen sends user actions to its cubit, the cubit emits new state back, and the cubit reaches down for data. Plain reads and writes go straight to a repository. A use case only exists when there's real logic to hold, either merging repositories (working out who the couple is, who a write is shared with) or domain math that doesn't belong in a cubit (expanding repeating events, cycle predictions and insights, comparing versions), so there are six of them in the whole app, not one per screen. Entities are the plain Dart objects every layer passes around, and the DTO and Hive adapter in `data/` are what map them to Firestore and to the local cache.

A few rules keep that shape honest:

- `domain/` has no UI in it. Entities are plain Dart, and a use case knows about repositories (plus `FirebaseAuth`, in the two account ones) and nothing UI-side.
- `data/` owns Firestore and the Hive cache. Cubits and widgets never talk to Firestore, and the only cubit holding Hive boxes is home, so it can wipe them on sign out.
- A feature doesn't import another feature, with account as the one real exception. Its `domain/` publishes `CoupleContext` and `SharingAudience` (plus the two use cases that resolve them) so the others can know who the couple is. The leaks still left are the cycles and home cubits reading account's repositories directly, and home importing the other features' entities so it can wipe every Hive box on sign out.
- `core/` is for the handful of widgets and the one repository that two or more features share. It imports no feature.
- `app/` wires it all together. The router is the composition root, and `config/dependencies.dart` is the `get_it` + `injectable` setup.

Here is the project's structure:

```
root/
├─ assets/                        # images, fonts, app logo, etc.
├─ android/                       # android project files
├─ ios/                           # ios project files
├─ functions/                     # cloud functions
└─ lib/
  ├── main.dart                   # app entry point
  ├── app/
  │   ├── router/                 # go_router setup, the composition root
  │   ├── theme/                  # app theming
  │   ├── app_cubit.dart          # global app state management
  │   ├── app_state.dart          # global app state definitions
  │   └── app.dart
  ├── config/
  │   ├── dependencies.dart       # get_it + injectable DI
  │   └── firebase_options.dart   # generated by FlutterFire CLI
  ├── constants/                  # app-wide constants
  ├── core/
  │   ├── data/                   # the image storage repository, shared by stories and account
  │   └── ui/                     # widgets shared by 2+ features, plus AsyncValue
  ├── features/
  │   ├── account/                # sign in, profile, partner. its domain/ is the only cross-feature import
  │   │   ├── data/               # repositories, DTOs, hive adapters
  │   │   ├── domain/
  │   │   │   ├── entities/       # the plain Dart objects every layer passes around
  │   │   │   └── usecases/       # domain logic, only where there is some
  │   │   └── ui/                 # one folder per screen: cubit, state, screen, components/ when needed
  │   ├── calendar/               # same three folders
  │   ├── cycles/                 # same three folders
  │   ├── home/                   # same three folders
  │   └── stories/                # same three folders
  ├── localizations/              # i18n support
  └── utils/                      # extensions, formatters, mixins
```

## Working on this with an AI assistant

This project runs on Flutter 3.47.2 / Dart 3.13.2, which is newer than most models' training data, so whatever assistant you use will tend to suggest widgets and APIs that have since been deprecated or removed. The [`dart-sdk-skills`](https://github.com/RandalSchwartz/dart-sdk-skills) skills fix that with a version-by-version reference for both SDKs, and they work with any agent that reads skills (Claude Code, Codex, Cursor, Copilot, Cline, Antigravity, and so on).

Install them once, globally, with the universal installer:

```
npx skills add RandalSchwartz/dart-sdk-skills -g
```

Or, if you're on Claude Code, through the plugin marketplace:

```
/plugin marketplace add RandalSchwartz/dart-sdk-skills
/plugin install dart-sdk-skills@dart-sdk-skills
```

Either way you get two skills that load on their own whenever they're relevant:

- `dart-sdk-changelog` covers Dart language features and core APIs, minimum SDK lookups, experimental flags, macros and augmentations
- `flutter-sdk-changelog` covers widget deprecations and their replacements (`WillPopScope` → `PopScope`, `withOpacity` → `withValues`, `MaterialState` → `WidgetState`), the Material 3 migration, and the Flutter-to-Dart version matrix

## License

Feel free to explore this project for inspiration and learning! It's licensed under MIT with a Commons Clause, which means you can use, modify, and study the code freely — just not for commercial purposes. See [LICENSE](LICENSE) for details.
