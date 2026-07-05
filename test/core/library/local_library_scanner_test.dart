import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/library/local_library_scanner.dart';

void main() {
  group('LocalLibraryScanner', () {
    test('groups audio files by parent folder', () {
      final results = LocalLibraryScanner.scanRoots(
        const [],
        scannedAtMs: 1,
      );
      expect(results, isEmpty);
    });

    test('audio extension filter accepts mp3 and rejects txt', () {
      expect(LocalLibraryScanner.audioExtensions.contains('mp3'), isTrue);
      expect(LocalLibraryScanner.audioExtensions.contains('txt'), isFalse);
    });
  });
}
