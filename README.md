# mtd

Your Own Todo List App built with Flutter.

## Features

- Create, edit, and delete todos
- Cross-platform (Android, iOS, Web)
- Clean and minimal UI

## Platform Support

| Platform | Status |
| -------- | ------ |
| Android  | ✅     |
| iOS      | ✅     |
| Web      | ✅     |

## Build Status

| Platform | Workflow |
| -------- | -------- |
| Android  | [![Build Android](https://github.com/NuengCoder/mtd/actions/workflows/build-android.yml/badge.svg)](https://github.com/NuengCoder/mtd/actions/workflows/build-android.yml) |
| iOS      | [![Build iOS](https://github.com/NuengCoder/mtd/actions/workflows/build-ios.yml/badge.svg)](https://github.com/NuengCoder/mtd/actions/workflows/build-ios.yml) |

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android Studio or Xcode (for platform builds)

### Installation

```bash
git clone https://github.com/NuengCoder/mtd.git
cd mtd
flutter pub get
```

### Run the app

```bash
flutter run           # auto-select connected device
flutter run -d chrome # run on web
flutter run -d ios    # run on iOS simulator
```

### Build for production

```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS (requires Xcode & Apple Developer account)
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart
└── ...
```

## Resources

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Flutter documentation](https://docs.flutter.dev/)
