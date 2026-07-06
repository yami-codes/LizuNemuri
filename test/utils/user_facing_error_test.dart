import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/utils/user_facing_error.dart';

void main() {
  group('userFacingError', () {
    test('PlayerException surfaces message instead of generic network copy', () {
      final err = PlayerException(0, 'Source error');
      expect(userFacingError(err), 'Source error');
    });

    test('PlayerException without message falls back to generic copy', () {
      final err = PlayerException(0, null);
      expect(userFacingError(err), Strings.networkErrorGeneric);
    });
  });
}
