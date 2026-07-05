# Xuro

[中文说明](README.md)

A beautiful and modern [ASMR.ONE](https://asmr.one) client application built with Flutter.

## Project Overview

Xuro is designed to provide a smooth and enjoyable ASMR listening experience with beautiful animations and a modern user interface. The immersive player, sleep-timer bedtime flow, and several interaction patterns are inspired by **[EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)** — see [Inspiration](#inspiration) below.

## Features

- Stable background playback
- Beautiful animations and clean UI design
- Subtitle/lyric display with VTT/LRC import support
- Playlist management
- Multi-dimensional browsing: tags, circles, voice actors
- Favorites collection
- Android 13+ notification permission support
- Floating lyric overlay (Android)
- Comprehensive settings system
- Smart caching (images, subtitles, audio files)
- Unified cache management
- **Eara-inspired (ongoing port)**
  - Monet cover backdrop + immersive player shell
  - Sleep timer fade-out and sleep-mode dim
  - Playback speed presets
  - Dual subtitles (original + LLM translation)

## Inspiration

Xuro’s immersive player, sleep-timer flow, and headphone-oriented controls are primarily inspired by **[EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)** — a Jetpack Compose + Media3 Android client built specifically for ASMR. Eara shows how cover-driven “Monet” backdrops, readable lyrics on tinted glass, stereo balance, and **A–B slice looping** on the seek bar can make long-form binaural content feel intentional rather than bolted onto a generic music player.

We have already ported and adapted several ideas for Flutter and cross-platform delivery:

- Blurred cover artwork with palette-derived accent colors (player canvas only)
- **Dual-line subtitles** with on-device LLM translation (Xuro-specific)
- Sleep timer: volume fade in the last 30 seconds + dimmed player overlay
- Preset playback speed (0.75×–1.5×)

See [`docs/inspiration_eara.md`](docs/inspiration_eara.md) for a full feature map and porting backlog. Eara remains the best reference for ASMR-specific features not yet in Xuro, including:

- **Segment looping (A–B slices)** on the progress bar
- **Dual-channel spectrum** and stereo balance for binaural stereo
- **Graphic EQ, scene reverb, and spatial effects** in a dedicated audio panel
- **Rich discovery UX** (filter chips, hot keywords, unified downloads hub)

Xuro’s strengths are a **first-party [asmr.one](https://asmr.one) API client**, **LLM subtitle translation**, **iOS support**, and **multilingual UI** (English, 中文, ไทย). If you enjoy Xuro’s player atmosphere, please explore the original project: [github.com/moyucc/EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer). **Xuro is not affiliated with Eara’s authors, asmr.one, or DLsite.**

## Requirements

- Flutter 3.27.0+
- Dart SDK >=3.2.3 <4.0.0
- Android: minSdk 21 / targetSdk 33
- Java 17

## Getting Started

```bash
git clone https://github.com/WuMe-sicx/Xuro.git
cd Xuro
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Project Structure

```
lib/
├── core/                 # Core functionality (audio, subtitle, theme, cache, platform)
├── data/                 # Data layer (API, models, repositories)
├── presentation/         # Presentation layer (ViewModels)
├── screens/              # Full-page screens
├── widgets/              # Reusable UI components
└── common/               # Common utilities and constants
```

## Development Guidelines

- [Development Guidelines](docs/guidelines_en.md)

## Contributing

Please read our [Development Guidelines](docs/guidelines_en.md) before making a contribution.

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike License (CC BY-NC-SA) - see the [LICENSE](LICENSE) file for details.

Original author: [asmroneapp](https://github.com/asmroneapp) | Original repo: [Yuro](https://github.com/asmroneapp/Yuro)

This license allows others to remix, tweak, and build upon your work non-commercially, as long as they credit you and license their new creations under the identical terms.
