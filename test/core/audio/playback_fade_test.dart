import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xuro/core/audio/utils/volume_fader.dart';
import 'package:xuro/core/settings/app_settings_service.dart';

void main() {
  group('VolumeFader', () {
    test('interpolate clamps progress and blends linearly', () {
      expect(VolumeFader.interpolate(1.0, 0.0, 0.0), 1.0);
      expect(VolumeFader.interpolate(1.0, 0.0, 0.5), 0.5);
      expect(VolumeFader.interpolate(1.0, 0.0, 1.0), 0.0);
      expect(VolumeFader.interpolate(0.2, 0.8, -1), 0.2);
      expect(VolumeFader.interpolate(0.2, 0.8, 2), 0.8);
    });

    test('stepCount is zero for non-positive duration', () {
      expect(VolumeFader.stepCount(0), 0);
      expect(VolumeFader.stepCount(-100), 0);
    });

    test('stepCount for 300ms at 16ms steps', () {
      expect(VolumeFader.stepCount(300), 19);
    });

    test('fadeSteps starts at from and ends at to', () {
      final steps = VolumeFader.fadeSteps(
        from: 0.8,
        to: 0.0,
        durationMs: 300,
      );
      expect(steps.first, closeTo(0.8, 0.001));
      expect(steps.last, closeTo(0.0, 0.001));
      expect(steps.length, VolumeFader.stepCount(300) + 1);
    });

    test('volumeAtStep is monotonic for fade-out', () {
      const total = 10;
      var prev = 1.0;
      for (var i = 0; i <= total; i++) {
        final v = VolumeFader.volumeAtStep(
          from: 1.0,
          to: 0.0,
          step: i,
          totalSteps: total,
        );
        expect(v, lessThanOrEqualTo(prev + 0.0001));
        prev = v;
      }
    });
  });

  group('AppSettingsService playback fade defaults', () {
    test('defaults enabled with 300ms', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = AppSettingsService(prefs);

      expect(settings.playbackFadeEnabled, isTrue);
      expect(settings.playbackFadeMs, 300);
    });

    test('setPlaybackFadeMs clamps to range', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = AppSettingsService(prefs);

      await settings.setPlaybackFadeMs(50);
      expect(settings.playbackFadeMs, AppSettingsService.minPlaybackFadeMs);

      await settings.setPlaybackFadeMs(5000);
      expect(settings.playbackFadeMs, AppSettingsService.maxPlaybackFadeMs);
    });

    test('setPlaybackFadeEnabled persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = AppSettingsService(prefs);

      await settings.setPlaybackFadeEnabled(false);
      expect(prefs.getBool('playback_fade_enabled'), isFalse);
    });
  });
}
