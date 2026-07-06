import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/audio/cache/audio_cache_manager.dart';

void main() {
  group('AudioCacheManager.shouldUseDirectStreaming', () {
    test('desktop targets direct progressive URL streaming', () {
      expect(
        AudioCacheManager.shouldUseDirectStreaming(isDesktop: true),
        isTrue,
      );
    });

    test('mobile keeps lock-caching path', () {
      expect(
        AudioCacheManager.shouldUseDirectStreaming(isDesktop: false),
        isFalse,
      );
    });
  });
}
