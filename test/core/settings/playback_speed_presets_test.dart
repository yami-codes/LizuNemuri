import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/settings/playback_speed_presets.dart';

void main() {
  group('PlaybackSpeedPresets', () {
    test('clamp keeps speed within supported range', () {
      expect(PlaybackSpeedPresets.clamp(0.1), PlaybackSpeedPresets.min);
      expect(PlaybackSpeedPresets.clamp(3.0), PlaybackSpeedPresets.max);
      expect(PlaybackSpeedPresets.clamp(1.25), 1.25);
    });

    test('isSelected uses tolerance', () {
      expect(PlaybackSpeedPresets.isSelected(1.0, 1.0), isTrue);
      expect(PlaybackSpeedPresets.isSelected(1.009, 1.0), isTrue);
      expect(PlaybackSpeedPresets.isSelected(1.2, 1.0), isFalse);
    });

    test('includes normal speed preset', () {
      expect(PlaybackSpeedPresets.values, contains(1.0));
    });
  });
}
