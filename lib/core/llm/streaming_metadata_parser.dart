import 'dart:convert';

/// Incrementally parses NDJSON metadata translation lines from a stream.
///
/// Expected format: one `{"id":"<id>","text":"..."}` object per line.
class StreamingMetadataParser {
  final StringBuffer _buffer = StringBuffer();

  List<MapEntry<String, String>> feed(String chunk) {
    _buffer.write(chunk);
    return _drainCompleteLines(flushRemainder: false);
  }

  List<MapEntry<String, String>> flush() =>
      _drainCompleteLines(flushRemainder: true);

  List<MapEntry<String, String>> _drainCompleteLines({
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

    final results = <MapEntry<String, String>>[];
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

  List<MapEntry<String, String>> _parseLine(String raw) {
    var line = raw.trim();
    if (line.isEmpty) return const [];
    if (line.startsWith('```')) return const [];

    final entry = _parseObject(line);
    if (entry != null) return [entry];

    if (line.startsWith('[')) {
      try {
        final decoded = jsonDecode(line);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((m) => _parseObjectMap(
                    m.map((k, v) => MapEntry(k.toString(), v)),
                  ))
              .whereType<MapEntry<String, String>>()
              .toList();
        }
      } catch (_) {
        return const [];
      }
    }

    return const [];
  }

  MapEntry<String, String>? _parseObject(String line) {
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

  MapEntry<String, String>? _parseObjectMap(Map<String, dynamic> obj) {
    final id = obj['id']?.toString();
    final text = obj['text']?.toString().trim();
    if (id == null || id.isEmpty || text == null || text.isEmpty) {
      return null;
    }
    return MapEntry(id, text);
  }
}
