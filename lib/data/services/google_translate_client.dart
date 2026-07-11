import 'package:dio/dio.dart';
import 'package:lizunemu/utils/logger.dart';

/// Unofficial free Google Translate client (no API key).
///
/// Uses `translate.googleapis.com/translate_a/single?client=gtx` — the same
/// endpoint used by Google Translate web/extension clients.
///
/// **Batching:** `client=gtx` only honors a single `q` per request. Multi-`q`
/// URLs still return a one-text JSON blob; parsing that with
/// `expectedCount > 1` yields empty strings. [translateBatch] therefore issues
/// one GET per input text.
class GoogleTranslateClient {
  static const _baseUrl = 'https://translate.googleapis.com';

  final Dio _dio;

  GoogleTranslateClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: const {
                'User-Agent':
                    'Mozilla/5.0 (compatible; Lizunemu/1.0; +https://github.com/yami-codes/LizuNemu)',
              },
            ));

  /// Translate a single string. [sourceLang] may be `auto`.
  Future<String> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;

    final results = await translateBatch(
      texts: [trimmed],
      targetLang: targetLang,
      sourceLang: sourceLang,
    );
    return results.isNotEmpty ? results.first : trimmed;
  }

  /// Translate multiple strings — one `q` request each (gtx does not batch).
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    final inputs = texts.map((t) => t.trim()).toList();
    if (inputs.isEmpty) return const [];

    final results = <String>[];
    for (final input in inputs) {
      if (input.isEmpty) {
        results.add('');
        continue;
      }
      try {
        final response = await _dio.get<dynamic>(
          '/translate_a/single',
          queryParameters: {
            'client': 'gtx',
            'sl': sourceLang,
            'tl': targetLang,
            'dt': 't',
            'q': input,
          },
        );
        final parsed = parseBatchResponse(response.data, expectedCount: 1);
        results.add(parsed.isNotEmpty ? parsed.first : '');
      } on DioException catch (e) {
        AppLogger.warning(
          'GoogleTranslateClient single failed: ${e.message}',
        );
        rethrow;
      }
    }
    return results;
  }

  /// Parse Google `translate_a/single` JSON into translated strings.
  ///
  /// Single-text response shape: `[[["translated","original",...],...],null,"ja"]`
  /// Callers should pass [expectedCount] `1` per request (see [translateBatch]).
  static List<String> parseBatchResponse(
    dynamic data, {
    required int expectedCount,
  }) {
    if (data is! List || data.isEmpty) {
      throw const FormatException('empty google translate response');
    }

    final segments = data[0];
    if (segments is! List) {
      throw const FormatException('invalid google translate segments');
    }

    // Always join as a single input: multi-chunk long text is one translation.
    // expectedCount > 1 on a single-text blob used to mis-parse flat rows into
    // empty strings — callers must not rely on multi-q responses anymore.
    final joined = _joinSegment(segments);
    if (expectedCount <= 1) return [joined];

    final results = <String>[joined];
    while (results.length < expectedCount) {
      results.add('');
    }
    return results.sublist(0, expectedCount);
  }

  static String _joinSegment(List<dynamic> segment) {
    final buffer = StringBuffer();
    for (final chunk in segment) {
      if (chunk is List && chunk.isNotEmpty && chunk[0] is String) {
        buffer.write(chunk[0] as String);
      }
    }
    return buffer.toString();
  }
}
