import 'dart:convert';

import 'package:lizunemu/core/lore/models/lore_event.dart';

/// One NDJSON line from a streaming lore track pass.
sealed class LoreTrackStreamItem {
  const LoreTrackStreamItem();
}

class LoreTrackStreamSummary extends LoreTrackStreamItem {
  final Map<String, dynamic> json;
  const LoreTrackStreamSummary(this.json);
}

class LoreTrackStreamEvent extends LoreTrackStreamItem {
  final Map<String, dynamic> json;
  const LoreTrackStreamEvent(this.json);
}

class LoreTrackStreamCarry extends LoreTrackStreamItem {
  final Map<String, dynamic> carryUpdates;
  const LoreTrackStreamCarry(this.carryUpdates);
}

/// Incrementally parses NDJSON lore track lines from an LLM stream.
///
/// Expected lines (any order tolerated; typically summary → events → carry):
/// `{"type":"summary",...}`
/// `{"type":"event",...}`
/// `{"type":"carry","carryUpdates":{...}}`
///
/// Also accepts a legacy single-object blob on flush (non-streaming fallback
/// if the model ignores NDJSON).
class StreamingLoreTrackParser {
  final StringBuffer _buffer = StringBuffer();

  List<LoreTrackStreamItem> feed(String chunk) {
    _buffer.write(chunk);
    return _drainCompleteLines(flushRemainder: false);
  }

  List<LoreTrackStreamItem> flush() =>
      _drainCompleteLines(flushRemainder: true);

  List<LoreTrackStreamItem> _drainCompleteLines({
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

    final results = <LoreTrackStreamItem>[];
    for (final raw in parts) {
      results.addAll(_parseLine(raw));
    }

    if (flushRemainder && remainder != null) {
      results.addAll(_parseLine(remainder));
    } else if (remainder != null) {
      _buffer.write(remainder);
    }

    return results;
  }

  List<LoreTrackStreamItem> _parseLine(String raw) {
    var line = raw.trim();
    if (line.isEmpty) return const [];
    if (line.startsWith('```')) return const [];

    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) return const [];
      final map = Map<String, dynamic>.from(decoded);
      return _fromObject(map);
    } catch (_) {
      return const [];
    }
  }

  List<LoreTrackStreamItem> _fromObject(Map<String, dynamic> map) {
    final type = map['type']?.toString();

    if (type == 'summary') {
      return [LoreTrackStreamSummary(map)];
    }
    if (type == 'event') {
      return [LoreTrackStreamEvent(map)];
    }
    if (type == 'carry') {
      final raw = map['carryUpdates'];
      if (raw is Map) {
        return [LoreTrackStreamCarry(Map<String, dynamic>.from(raw))];
      }
      return const [];
    }

    // Legacy blob: {summary, events, carryUpdates} without per-line type.
    if (map.containsKey('events') ||
        (map.containsKey('summary') && map['summary'] is Map)) {
      final out = <LoreTrackStreamItem>[];
      final summaryJson = map['summary'];
      if (summaryJson is Map) {
        out.add(
          LoreTrackStreamSummary(Map<String, dynamic>.from(summaryJson)),
        );
      } else if (summaryJson is String) {
        out.add(
          LoreTrackStreamSummary({
            'summary': summaryJson,
            if (map['trackKey'] != null) 'trackKey': map['trackKey'],
            if (map['lowConfidence'] != null)
              'lowConfidence': map['lowConfidence'],
            if (map['hasSubtitles'] != null)
              'hasSubtitles': map['hasSubtitles'],
          }),
        );
      }
      final events = map['events'];
      if (events is List) {
        for (final e in events) {
          if (e is Map) {
            out.add(LoreTrackStreamEvent(Map<String, dynamic>.from(e)));
          }
        }
      }
      final carry = map['carryUpdates'];
      if (carry is Map) {
        out.add(LoreTrackStreamCarry(Map<String, dynamic>.from(carry)));
      }
      return out;
    }

    // Untyped heuristics (models that omit `type`).
    if (map.containsKey('summary') && map['summary'] is String) {
      return [LoreTrackStreamSummary(map)];
    }
    if (map.containsKey('deltas') ||
        map.containsKey('atMs') ||
        map.containsKey('kind')) {
      return [LoreTrackStreamEvent(map)];
    }
    if (map.containsKey('carryUpdates')) {
      final raw = map['carryUpdates'];
      if (raw is Map) {
        return [LoreTrackStreamCarry(Map<String, dynamic>.from(raw))];
      }
    }

    return const [];
  }
}

/// Builds a [LoreTimelineEvent] from a streamed event map (fills defaults).
LoreTimelineEvent loreEventFromStreamMap(
  Map<String, dynamic> m, {
  required String trackKey,
  required String Function() newId,
  bool forceSpeculative = false,
}) {
  final map = Map<String, dynamic>.from(m)..remove('type');
  map['trackKey'] = map['trackKey'] ?? trackKey;
  map['id'] = map['id'] ?? newId();
  if (forceSpeculative) map['speculative'] = true;
  return LoreTimelineEvent.fromJson(map);
}
