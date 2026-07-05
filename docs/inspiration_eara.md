# Inspiration: EaraAsmrPlayer

> Reference for porting ASMR-first UX patterns into Xuro.  
> Upstream: **[EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)** (Android, Jetpack Compose + Media3).

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

## Planned / high-value ports (asmr.one–native)

Prioritized for Flutter + direct API (skip DLsite scraper / full local scan unless scope changes):

1. Backdrop **clarity slider** (Eara: cover clarity 0–100%)
2. **Play/pause volume fade** (separate from sleep-timer fade)
3. **A–B segment loop** + slice markers on progress bar
4. **Central downloads manager** screen (`DownloadRepository` already exists)
5. **Kinetic centered lyrics** (Apple-style scroll follow)
6. **Search filter chips** mapped to asmr.one query params
7. **Hot discovery** pattern (recommender + tag surfacing)
8. **Stereo balance / spectrum** — only when a cross-platform or Android-first path is acceptable; otherwise skip
9. **User work collections** (lightweight “album groups” over favorites)
10. **Listening statistics** (optional, local-only)

---

## Explicitly out of scope (different product shape)

- DLsite HTML scraper + Play cloud sync
- Full folder-scan local library as primary home
- Listen-together social backend
- Full 10-band EQ + scene reverb without native audio graph on both platforms

---

## Xuro advantages (keep investing here)

- First-party **asmr.one API** + mirror nodes (no scraper fragility)
- **LLM subtitle translation** + dual-line display
- **Cross-platform** (iOS + Android; desktop in progress)
- **i18n** (en / zh / th)
- User subtitle import + offline downloaded subtitles

---

## Key Eara source map (for developers)

| Area | Kotlin entry points |
|------|---------------------|
| Player shell | `ui/player/NowPlayingScreen.kt`, `CoverArtworkBackground.kt`, `PlayerDynamicHue.kt` |
| Lyrics | `AppleLyricsView.kt`, `LyricsPage.kt`, `FloatingLyricsOverlay.kt` |
| Audio FX | `EqualizerPanel.kt`, `GraphicEqualizerAudioProcessor.kt`, `BalanceAudioProcessor.kt`, `ChannelSpectrumView.kt` |
| Slices | `SliceLoopEngine.kt`, `NowPlayingProgress.kt` |
| Sleep | `SleepTimerSheet.kt`, `VolumeFader.kt`, `FadingPlayer.kt` |
| Search | `SearchScreen.kt`, `SearchViewModel.kt`, `SearchFilterOption.kt` |
| Downloads | `DownloadManager.kt`, `DownloadsScreen.kt` |
| Settings | `SettingsScreen.kt` |
