import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/audio/effects/audio_effects_controller.dart';

void main() {
  test('AudioEffectsController unsupported until bind', () {
    final fx = AudioEffectsController();
    expect(fx.isSupported, isFalse);
    expect(fx.enabled, isFalse);
  });
}
