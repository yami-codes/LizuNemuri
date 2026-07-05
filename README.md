# Lizunemu

[中文说明](README_zh.md) · [ภาษาไทย](README_th.md)

A beautiful and modern [ASMR.ONE](https://asmr.one) client application built with Flutter (rebranded from **Xuro** 2.0).

## Project Overview

Lizunemu is designed to provide a smooth and enjoyable ASMR listening experience with beautiful animations and a modern user interface. The immersive player, sleep-timer bedtime flow, and several interaction patterns are inspired by **[EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)**.

## Features

- Stable background playback with media notifications
- Cover-driven Monet dynamic theme + kinetic centered lyrics
- **LLM subtitle translation** (OpenAI-compatible / OpenRouter) with streaming line-by-line updates, batch split modes, and usage history
- Dual-line subtitle display (original + translation)
- Offline downloads, local library scan, DLsite Play library
- Playlist management and multi-dimensional browsing (tags, circles, voice actors)
- Floating lyric overlay (Android), Android graphic EQ
- Multilingual UI (English, 中文, ไทย)
- Android / iOS / Web / Windows desktop

## Requirements

- Flutter 3.27.0+ (FVM-pinned — see `.fvmrc`)
- Dart SDK >=3.2.3 <4.0.0
- Android: minSdk 21 / targetSdk 33
- Java 17

## Getting Started

```bash
git clone https://github.com/yami-codes/LizuNemu.git
cd LizuNemu

fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run
fvm flutter test
```

## Development Guidelines

- [Development Workflow (mandatory)](docs/dev_workflow.md)
- [Development Guidelines](docs/guidelines_en.md)
- [TODO tracker](docs/todos/)

## License

This project is licensed under CC BY-NC-SA 4.0 — see [LICENSE](LICENSE).
