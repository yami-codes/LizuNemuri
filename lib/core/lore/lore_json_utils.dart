import 'dart:convert';

/// Helpers for scraping structured JSON out of messy LLM replies.
class LoreJsonUtils {
  LoreJsonUtils._();

  static String? extractJsonBlob(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;

    final fence = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    );
    final fenceMatch = fence.firstMatch(text);
    if (fenceMatch != null) {
      text = fenceMatch.group(1)!.trim();
    }

    final objStart = text.indexOf('{');
    final arrStart = text.indexOf('[');
    int start;
    if (objStart < 0 && arrStart < 0) return null;
    if (objStart < 0) {
      start = arrStart;
    } else if (arrStart < 0) {
      start = objStart;
    } else {
      start = objStart < arrStart ? objStart : arrStart;
    }

    final open = text[start];
    final close = open == '{' ? '}' : ']';
    var depth = 0;
    var inString = false;
    var escape = false;
    for (var i = start; i < text.length; i++) {
      final ch = text[i];
      if (inString) {
        if (escape) {
          escape = false;
        } else if (ch == '\\') {
          escape = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
        continue;
      }
      if (ch == open) depth++;
      if (ch == close) {
        depth--;
        if (depth == 0) {
          return text.substring(start, i + 1);
        }
      }
    }
    return null;
  }

  static Map<String, dynamic>? parseObject(String raw) {
    final blob = extractJsonBlob(raw);
    if (blob == null) return null;
    try {
      final decoded = jsonDecode(blob);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  static List<dynamic>? parseArray(String raw) {
    final blob = extractJsonBlob(raw);
    if (blob == null) return null;
    try {
      final decoded = jsonDecode(blob);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['items'] is List) {
        return decoded['items'] as List;
      }
    } catch (_) {}
    return null;
  }

  static String trackKeyFor({
    required int index,
    String? hash,
    String? mediaDownloadUrl,
    String? title,
  }) {
    if (hash != null && hash.trim().isNotEmpty) return hash.trim();
    if (mediaDownloadUrl != null && mediaDownloadUrl.trim().isNotEmpty) {
      return mediaDownloadUrl.trim();
    }
    final t = (title ?? 'track').trim();
    return 'idx:$index:$t';
  }
}
