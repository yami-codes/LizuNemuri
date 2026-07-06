import 'package:dio/dio.dart';
import 'package:lizunemu/utils/logger.dart';

/// Unofficial free Google Translate client (no API key).
///
/// Uses `translate.googleapis.com/translate_a/single?client=gtx` — the same
/// endpoint used by Google Translate web/extension clients.
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

  /// Translate multiple strings in one request (multiple `q` params).
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String targetLang,
    String sourceLang = 'auto',
  }) async {
    final inputs = texts.map((t) => t.trim()).toList();
    if (inputs.isEmpty) return const [];

    try {
      final response = await _dio.get<dynamic>(
        '/translate_a/single',
        queryParameters: {
          'client': 'gtx',
          'sl': sourceLang,
          'tl': targetLang,
          'dt': 't',
          'q': inputs,
        },
        options: Options(listFormat: ListFormat.multi),
      );
      return parseBatchResponse(response.data, expectedCount: inputs.length);
    } on DioException catch (e) {
      AppLogger.warning('GoogleTranslateClient batch failed: ${e.message}');
      rethrow;
    }
  }

  /// Parse Google `translate_a/single` JSON into translated strings.
  ///
  /// Single-text response shape: `[[["translated","original",...],...],null,"ja"]`
  /// Multi-text responses append one inner array per `q` parameter.
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

    if (expectedCount <= 1) {
      return [_joinSegment(segments)];
    }

    final results = <String>[];
    for (final segment in segments) {
      if (segment is List) {
        results.add(_joinSegment(segment));
      }
    }

    while (results.length < expectedCount) {
      results.add('');
    }
    if (results.length > expectedCount) {
      return results.sublist(0, expectedCount);
    }
    return results;
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
