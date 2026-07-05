# Inspiration: EaraAsmrPlayer

> Reference for porting ASMR-first UX patterns into Xuro.  
> Upstream: **[EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)** (Android, Jetpack Compose + Media3).

**Locked product direction:** [`eara_ui_north_star.md`](eara_ui_north_star.md) (grill-me 2026-07-05).

Eara is the primary **product north star** for Xuro’s player atmosphere, bedtime flow, and headphone-oriented interactions. Xuro is **not affiliated** with Eara’s authors, asmr.one, or DLsite.

---

## Why Eara fits ASMR listening

Eara treats ASMR as **album-centric, ear-first listening** — not a generic music player skin:

- **Immersive shell** — blurred cover backdrop, Monet/dynamic hue from artwork, readable lyrics on tinted glass
- **Ear engineering** — EQ, scene reverb, L/R balance, dual-channel spectrum, speed + pitch
- **Segment workflow** — A–B slices on the seek bar for repeating whispers / ear-cleaning passages
- **Bedtime** — sleep timer, play/pause fades, output-disconnect handling
- **Discovery depth** — filter chips, hot keywords, multi-source search enrichment
- **Offline hub** — unified downloads screen, subtitle auto-match, local library tags/groups

---

## Already adapted in Xuro (PR [#11](https://github.com/yami-codes/Xuro/pull/11) track)

| Eara idea | Xuro implementation |
|-----------|---------------------|
| Monet cover backdrop | `cover_artwork_background.dart`, `player_hue_derivation.dart`, `player_immersive_scope.dart` |
| Readable lyrics on backdrop | `lyric_line.dart`, immersive scope colors |
| Sleep timer + fade | `sleep_timer_controller.dart` (30s volume fade, dim overlay) |
| Playback speed presets | `playback_speed_presets.dart`, `player_speed_button.dart` |
| Dual-line subtitles | `LlmSubtitleDisplayMode.dual` (original + LLM translation) |

---

## Roadmap (from north star — ordered)

| Milestone | Scope |
|-----------|--------|
| **A** (next) | Player motion, shared backdrop, lyrics surface toggle |
| **B** | Kinetic centered lyrics |
| **C** | Global Monet-from-cover (drop static color variants) |
| **D** | Bottom nav: Library / Search / Hot + drawer |
| **E** | Full-app Eara-density reskin |
| **F** | Local folder scan library |
| **G** | DLsite integration (legal review) |
| **H** | Audio plugin spike for EQ/spectrum |

---

## Xuro advantages (keep investing here)

- First-party **asmr.one API** + mirror nodes
- **LLM subtitle translation** + dual-line display
- **Cross-platform** (iOS + Android; desktop in progress)
- **i18n** (en / zh / th)
- User subtitle import + offline downloaded subtitles

---

## Key Eara source map (for developers)

| Area | Kotlin entry points |
|------|---------------------|
| Player shell | `ui/player/NowPlayingScreen.kt`, `CoverArtworkBackground.kt`, `PlayerDynamicHue.kt`, `NowPlayingMotion.kt` |
| Lyrics | `AppleLyricsView.kt`, `LyricsPage.kt`, `FloatingLyricsOverlay.kt` |
| Audio FX | `EqualizerPanel.kt`, `GraphicEqualizerAudioProcessor.kt`, `BalanceAudioProcessor.kt`, `ChannelSpectrumView.kt` |
| Slices | `SliceLoopEngine.kt`, `NowPlayingProgress.kt` |
| Sleep | `SleepTimerSheet.kt`, `VolumeFader.kt`, `FadingPlayer.kt` |
| Search | `SearchScreen.kt`, `SearchViewModel.kt`, `SearchFilterOption.kt` |
| Library | `LibraryScreen.kt`, `libraryviewmodel.kt`, `ScanRootsStore.kt` |
| DLsite | `DlsiteLoginScreen.kt`, `DLSiteScraper.kt`, `DlsitePlayLibraryClient.kt` |
| Downloads | `DownloadManager.kt`, `DownloadsScreen.kt` |
| Settings | `SettingsScreen.kt` |
