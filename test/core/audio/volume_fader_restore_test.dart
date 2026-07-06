import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/audio/utils/volume_fader.dart';

void main() {
  group('VolumeFader.shouldRestoreVolume', () {
    test('returns true when playing but volume stuck near zero', () {
      expect(
        VolumeFader.shouldRestoreVolume(
          isPlaying: true,
          currentVolume: 0.0,
          targetVolume: 1.0,
        ),
        isTrue,
      );
    });

    test('returns false when volume already near target', () {
      expect(
        VolumeFader.shouldRestoreVolume(
          isPlaying: true,
          currentVolume: 0.9,
          targetVolume: 1.0,
        ),
        isFalse,
      );
    });

    test('returns false when not playing', () {
      expect(
        VolumeFader.shouldRestoreVolume(
          isPlaying: false,
          currentVolume: 0.0,
          targetVolume: 1.0,
        ),
        isFalse,
      );
    });
  });
}
