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

Built with Flutter and Firebase, using BLoC for state management and dependency injection via `get_it` + `injectable`. The AI insights are powered by Gemini through the `firebase_ai` package. Other notable packages include `go_router` for navigation, `hive` for local storage, and `super_editor` for rich text editing.

Here is the project's structure:
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/                 # go_router setup
│   └── theme/                  # app theming
├── config/
│   ├── dependencies.dart       # get_it + injectable DI
│   └── firebase_options.dart
├── constants/
├── data/
│   ├── models/                 # data models (calendar events, cycles, stories)
│   ├── repositories/           # data layer abstractions
│   └── services/               # business logic (AI insights, predictions)
├── localizations/              # i18n support
├── ui/
│   ├── features/               # feature modules with BLoC
│   └── shared_widgets/         # reusable components
└── utils/                      # extensions, formatters, mixins
```

## License

MIT with Commons Clause — free to use and modify, just not for commercial use. See [LICENSE](LICENSE) for details.

