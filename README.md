# Xuro

[中文说明](README_zh.md) · [ภาษาไทย](README_th.md)

A beautiful and modern [ASMR.ONE](https://asmr.one) client application built with Flutter.

## Project Overview

Xuro is designed to provide a smooth and enjoyable ASMR listening experience with beautiful animations and a modern user interface.

## Features

- Stable background playback
- Beautiful animations and clean UI design
- Subtitle/lyric display with VTT/LRC import support
- **LLM subtitle translation** (OpenAI-compatible / OpenRouter) with streaming line-by-line updates
- Playlist management
- Multi-dimensional browsing: tags, circles, voice actors
- Favorites collection
- Android 13+ notification permission support
- Floating lyric overlay (Android)
- Comprehensive settings system
- Smart caching (images, subtitles, audio files)
- Unified cache management
- Local media download for offline playback

## Requirements

- Flutter 3.27.0+ (FVM-pinned — see `.fvmrc`)
- Dart SDK >=3.2.3 <4.0.0
- Android: minSdk 21 / targetSdk 33
- Java 17

## Getting Started

```bash
git clone https://github.com/yami-codes/Xuro.git
cd Xuro

# Install dependencies (prefer FVM)
fvm flutter pub get

# Code generation (freezed + json_serializable)
fvm dart run build_runner build --delete-conflicting-outputs

# Run the app (debug)
fvm flutter run

# Run tests
fvm flutter test

# Build release APK
fvm flutter build apk --release
```

## Project Structure

```
lib/
├── core/                 # Core functionality (audio, subtitle, theme, cache, LLM, platform)
├── data/                 # Data layer (API, models, repositories)
├── presentation/         # Presentation layer (ViewModels)
├── screens/              # Full-page screens
├── widgets/              # Reusable UI components
└── common/               # Common utilities and constants
```

## Development Guidelines

- [Development Workflow (mandatory)](docs/dev_workflow.md)
- [Development Guidelines](docs/guidelines_en.md)
- [TODO tracker](docs/todos/)

## Contributing

Please read our [Development Workflow](docs/dev_workflow.md) and [Development Guidelines](docs/guidelines_en.md) before making a contribution.

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike License (CC BY-NC-SA) — see the [LICENSE](LICENSE) file for details.

Original author: [asmroneapp](https://github.com/asmroneapp) | Original repo: [Yuro](https://github.com/asmroneapp/Yuro)
