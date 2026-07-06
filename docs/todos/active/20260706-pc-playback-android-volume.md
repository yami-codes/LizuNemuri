# PC playback + subtitle preview + Android silent-until-volume

- **Created**: 2026-07-06
- **Owner**: cursor-agent
- **Status**: active

## 1. Goal

Fix desktop playback/subtitle preview failures and Android tracks that stay silent until the user adjusts volume.

## 2. Scope

**In scope:**
- Desktop: direct URL streaming (no LockCaching byte-stream proxy on Windows/Linux/macOS)
- Linux: `just_audio_media_kit` backend registration
- Subtitle fetch: tokenless Dio + plain text response for presigned URLs
- Android: defer volume fade-in until audio pipeline is ready
- Clearer playback error mapping for PlayerException

**Out of scope:** Full offline transcode of unsupported desktop codecs

## 3. Acceptance

- [x] PC streams `mediaDownloadUrl` via ProgressiveAudioSource
- [x] Subtitle preview loads presigned URLs without AuthInterceptor
- [x] Android resume fade waits for ProcessingState.ready before ramping volume
- [x] Tests + analyze pass

## 4. Steps

- [x] AudioCacheManager + PlaylistBuilder desktop paths
- [x] SubtitleLoader + service_locator Dio
- [x] AudioPlayerService resume fade fix
- [x] Linux just_audio_media_kit init
- [x] Tests + analyze
