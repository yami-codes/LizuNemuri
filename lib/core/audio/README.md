# Audio Core

## Current Architecture

### 1. Event-Driven System
- RxDart-based event hub
- Unified event definitions and handling
- Supports event filtering and transformation

### 2. Core Service (AudioPlayerService)
- Implements `IAudioPlayerService`
- Dependencies managed via dependency injection
- Coordinates all audio components

### 3. State Management
- `PlaybackStateManager` maintains playback state
- State updates broadcast through `EventHub`
- Supports state persistence

### 4. Notification Integration
- Built on the `audio_service` package
- Responds to system media controls
- Supports background playback

### 5. Dependency Injection
All dependencies are registered through GetIt:

```dart
void setupServiceLocator() {
  // Register EventHub
  getIt.registerLazySingleton(() => PlaybackEventHub());

  // Register audio service
  getIt.registerLazySingleton<IAudioPlayerService>(
    () => AudioPlayerService(
      eventHub: getIt(),
      stateRepository: getIt(),
    ),
  );
}
```

## Notes

- All state updates go through `EventHub`
- Avoid direct calls between components
- Prefer dependency injection
- Keep each component single-purpose
