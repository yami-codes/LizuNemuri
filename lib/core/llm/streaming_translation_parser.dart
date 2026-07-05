import 'dart:convert';

/// Incrementally parses NDJSON subtitle translation lines from a stream.
///
/// Expected format: one `{"index":N,"text":"..."}` object per line.
class StreamingTranslationParser {
  final StringBuffer _buffer = StringBuffer();

  /// Feed a new text chunk; returns newly completed index→text pairs.
  List<MapEntry<int, String>> feed(String chunk) {
    _buffer.write(chunk);
    return _drainCompleteLines(flushRemainder: false);
  }

  /// Parse any trailing partial line after the stream ends.
  List<MapEntry<int, String>> flush() =>
      _drainCompleteLines(flushRemainder: true);

  List<MapEntry<int, String>> _drainCompleteLines({
    required bool flushRemainder,
  }) {
    final text = _buffer.toString();
    _buffer.clear();

    final endsWithNewline = text.endsWith('\n');
    final parts = text.split('\n');

    String? remainder;
    if (!endsWithNewline && parts.isNotEmpty && !flushRemainder) {
      remainder = parts.removeLast();
    }

    final results = <MapEntry<int, String>>[];
    for (final raw in parts) {
      results.addAll(_parseLine(raw));
    }

    if (flushRemainder && remainder == null && parts.isEmpty && text.isNotEmpty) {
      results.addAll(_parseLine(text));
    } else if (flushRemainder && remainder != null) {
      results.addAll(_parseLine(remainder));
    } else if (remainder != null) {
      _buffer.write(remainder);
    }

    return results;
  }

  List<MapEntry<int, String>> _parseLine(String raw) {
    var line = raw.trim();
    if (line.isEmpty) return const [];

    // Tolerate markdown fence fragments the model might emit mid-stream.
    if (line.startsWith('```')) return const [];

    final entry = _parseObject(line);
    if (entry != null) return [entry];

    // Fallback: model returned a JSON array in one shot (non-streaming compat).
    if (line.startsWith('[')) {
      try {
        final decoded = jsonDecode(line);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((m) => _parseObjectMap(
                    m.map((k, v) => MapEntry(k.toString(), v)),
                  ))
              .whereType<MapEntry<int, String>>()
              .toList();
        }
      } catch (_) {
        return const [];
      }
    }

    return const [];
  }

  MapEntry<int, String>? _parseObject(String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is Map) {
        return _parseObjectMap(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  MapEntry<int, String>? _parseObjectMap(Map<String, dynamic> obj) {
    final index = obj['index'];
    final text = obj['text'];
    if (text is! String) return null;
    if (index is int) return MapEntry(index, text.trim());
    if (index is num) return MapEntry(index.toInt(), text.trim());
    return null;
  }
}
