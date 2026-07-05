# Audio plugin evaluation (Milestone H)

> **Date:** 2026-07-05  
> **North star:** [`docs/eara_ui_north_star.md`](eara_ui_north_star.md) §8C  
> **Decision:** Ship **just_audio built-in `AndroidEqualizer`** on Android v1; defer balance/spectrum/reverb.

---

## Question

Eara uses Media3 PCM processors (EQ, balance, spectrum, reverb). Xuro stays on **Flutter + just_audio**. What path unlocks ear-FX without a Kotlin rewrite?

---

## Options evaluated

| Option | EQ | L/R balance | Spectrum | Cross-platform | Verdict |
|--------|----|-------------|----------|----------------|---------|
| **just_audio `AndroidEqualizer` + `AudioPipeline`** | ✅ Android | ❌ | ❌ | Android FX only | **✅ v1 pick** |
| `audio_service` alone | ❌ | ❌ | ❌ | Yes | Keep for notifications; not an FX layer |
| `flutter_sound` | Partial | ❌ | ❌ | Yes | Heavy migration; duplicates just_audio |
| `aura_music_kit` | Wraps just_audio EQ | ❌ | ❌ | Android+iOS | Extra dep; no gain over native just_audio API |
| Custom MethodChannel + Media3 | ✅ | ✅ | ✅ | Android only | Eara-parity but high maintenance; phase 2 |
| `ffmpeg` / PCM tap in Dart | ✅ | ✅ | Possible | Yes | CPU/battery cost; complex with gapless playlist |

---

## Recommendation (locked for v1)

1. **Use `AndroidEqualizer`** already in **just_audio 0.9.x**:
   ```dart
   final equalizer = AndroidEqualizer();
   final player = AudioPlayer(
     audioPipeline: AudioPipeline(androidAudioEffects: [equalizer]),
   );
   ```
2. Expose via `AudioEffectsController` + player **Equalizer** sheet (Settings → Playback + player AppBar on Android).
3. **Do not** add a second playback engine.

### Not in v1 (explicit non-goals)

- **Stereo balance** — no stable just_audio API; needs custom Android processor (Eara `BalanceAudioProcessor`).
- **Live FFT / dual-channel spectrum** — needs PCM tap or platform visualizer; evaluate with Media3 spike in phase 2.
- **Scene reverb** — same as balance; Android-only native module.

---

## Phase 2 (if product asks)

| Feature | Suggested path |
|---------|----------------|
| Balance + reverb | Android `MethodChannel` wrapping Media3 `AudioProcessor` chain **in front of** existing player, or fork playback on Android only |
| Spectrum UI | `Visualizer` / ExoPlayer analytics callback → EventChannel → Flutter `CustomPainter` |
| iOS EQ | `AVAudioUnitEQ` via platform channel (no just_audio built-in) |

---

## Implementation in Xuro

| File | Role |
|------|------|
| `lib/core/audio/effects/audio_effects_controller.dart` | EQ enable + parameters |
| `lib/core/audio/audio_player_service.dart` | `AudioPipeline(androidAudioEffects: [equalizer])` on Android |
| `lib/widgets/player/player_equalizer_sheet.dart` | Band sliders UI |
| `lib/screens/settings/settings_screen.dart` | Playback → Equalizer entry |

---

## References

- [just_audio AndroidEqualizer](https://pub.dev/documentation/just_audio/latest/just_audio/AndroidEqualizer-class.html)
- Eara: `EqualizerPanel.kt`, `GraphicEqualizerAudioProcessor.kt`, `BalanceAudioProcessor.kt`, `ChannelSpectrumView.kt`
