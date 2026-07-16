import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/lore/work_lore_service.dart';
import 'package:lizunemu/data/services/exceptions/llm_translation_exception.dart';

void main() {
  group('loreSoftRetryDelay', () {
    test('grows with attempt and stays bounded', () {
      final d1 = loreSoftRetryDelay(1, random: _FixedRandom(0));
      final d3 = loreSoftRetryDelay(3, random: _FixedRandom(0));
      final d9 = loreSoftRetryDelay(9, random: _FixedRandom(0));
      expect(d1.inMilliseconds, greaterThanOrEqualTo(500));
      expect(d3.inMilliseconds, greaterThan(d1.inMilliseconds));
      expect(d9.inMilliseconds, lessThanOrEqualTo(8000 + 4000));
    });
  });

  group('loreIsHardLlmError', () {
    test('classifies hard vs soft', () {
      expect(
        loreIsHardLlmError(
          const LlmTranslationException(
            LlmTranslationErrorType.rateLimited,
            '429',
          ),
        ),
        isTrue,
      );
      expect(
        loreIsHardLlmError(
          const LlmTranslationException(
            LlmTranslationErrorType.network,
            'timeout',
          ),
        ),
        isFalse,
      );
      expect(
        loreIsHardLlmError(
          const LlmTranslationException(
            LlmTranslationErrorType.invalidResponse,
            'json',
          ),
        ),
        isFalse,
      );
    });
  });
}

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;
  @override
  int nextInt(int max) => value % max;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}
