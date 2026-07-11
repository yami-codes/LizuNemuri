import 'dart:math' as math;

import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';

/// One param change clip on the track timeline (video-editor style).
class LoreParamSpan {
  final String eventId;
  final String key;
  final String label;
  final int startMs;
  final int endMs;
  final dynamic from;
  final dynamic to;
  final bool numeric;
  final LoreEventKind kind;
  final String title;

  const LoreParamSpan({
    required this.eventId,
    required this.key,
    required this.label,
    required this.startMs,
    required this.endMs,
    required this.from,
    required this.to,
    required this.numeric,
    required this.kind,
    required this.title,
  });

  bool contains(int positionMs) =>
      positionMs >= startMs && positionMs < endMs;

  bool get isInstant => endMs <= startMs;
}

/// Discrete status snap that just crossed — UI can pulse the row.
class LoreChangePulse {
  final String key;
  final dynamic from;
  final dynamic to;
  final String eventId;
  final int atMs;

  const LoreChangePulse({
    required this.key,
    required this.from,
    required this.to,
    required this.eventId,
    required this.atMs,
  });
}

/// Bidirectional projection of character params from timeline events.
class LorePlaybackSnapshot {
  final String? trackKey;
  final String? resolvedTrackKey;
  final String? trackTitle;
  final int positionMs;
  final String? focusCharacterId;
  final LoreCharacter? focusCharacter;
  final List<LoreParam> projectedParams;
  final LoreTimelineEvent? currentEvent;
  /// Current-track events that have started (atMs <= position).
  final List<LoreTimelineEvent> revealedEvents;
  final List<LoreTimelineEvent> upcomingEvents;
  /// All current-track events as resolved spans (for the editor timeline).
  final List<LoreParamSpan> trackSpans;
  /// Spans active under the playhead.
  final List<LoreParamSpan> activeSpans;
  /// Discrete snaps in a recent window around [positionMs].
  final List<LoreChangePulse> changePulses;
  /// Ruler end for the current track timeline UI.
  final int trackTimelineEndMs;

  const LorePlaybackSnapshot({
    this.trackKey,
    this.resolvedTrackKey,
    this.trackTitle,
    required this.positionMs,
    this.focusCharacterId,
    this.focusCharacter,
    this.projectedParams = const [],
    this.currentEvent,
    this.revealedEvents = const [],
    this.upcomingEvents = const [],
    this.trackSpans = const [],
    this.activeSpans = const [],
    this.changePulses = const [],
    this.trackTimelineEndMs = 0,
  });
}

class LoreStateProjector {
  /// Default ramp when an event has no explicit end (clamped by next cue).
  static const int defaultRampMs = 2500;

  /// Window after a discrete snap still counts as a "pulse" for UI.
  static const int pulseWindowMs = 1200;

  /// Strip extensions / "no SFX" markers so remasters map to the lore track.
  static String normalizeTrackTitle(String title) {
    var t = title.trim();
    t = t.replaceAll(
      RegExp(r'\.(mp3|wav|flac|m4a|ogg|aac)$', caseSensitive: false),
      '',
    );
    t = t.replaceAll(RegExp(r'[（(]\s*无效果音\s*[）)]'), '');
    t = t.replaceAll(
      RegExp(r'[（(]\s*no[\s\-]?sfx\s*[）)]', caseSensitive: false),
      '',
    );
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    return t;
  }

  /// Map a playback file key/title onto the pack's canonical lore trackKey.
  static String? resolveTrackKey({
    required WorkLorePack pack,
    String? trackKey,
    String? trackTitle,
    int? trackIndex,
  }) {
    final summaries = pack.trackSummaries;
    final eventKeys = pack.events.map((e) => e.trackKey).toSet();

    bool known(String key) =>
        summaries.any((s) => s.trackKey == key) || eventKeys.contains(key);

    if (trackKey != null && trackKey.isNotEmpty && known(trackKey)) {
      if (eventKeys.contains(trackKey)) return trackKey;
      final self = summaries.where((s) => s.trackKey == trackKey);
      if (self.isNotEmpty) {
        final norm = normalizeTrackTitle(self.first.trackTitle);
        for (final s in summaries) {
          if (normalizeTrackTitle(s.trackTitle) == norm &&
              eventKeys.contains(s.trackKey)) {
            return s.trackKey;
          }
        }
      }
      return trackKey;
    }

    final title = trackTitle?.trim();
    if (title != null && title.isNotEmpty) {
      for (final s in summaries) {
        if (s.trackTitle == title && known(s.trackKey)) {
          return _preferKeyWithEvents(s.trackKey, summaries, eventKeys);
        }
      }
      final norm = normalizeTrackTitle(title);
      if (norm.isNotEmpty) {
        LoreTrackSummary? withEvents;
        LoreTrackSummary? any;
        for (final s in summaries) {
          if (normalizeTrackTitle(s.trackTitle) != norm) continue;
          any ??= s;
          if (eventKeys.contains(s.trackKey)) {
            withEvents = s;
            break;
          }
        }
        final hit = withEvents ?? any;
        if (hit != null) return hit.trackKey;
      }
    }

    if (trackIndex != null && trackIndex >= 0) {
      for (final s in summaries) {
        if (s.trackIndex == trackIndex) {
          return _preferKeyWithEvents(s.trackKey, summaries, eventKeys);
        }
      }
    }

    if (trackKey != null && trackKey.isNotEmpty) return trackKey;
    return null;
  }

  static String _preferKeyWithEvents(
    String key,
    List<LoreTrackSummary> summaries,
    Set<String> eventKeys,
  ) {
    if (eventKeys.contains(key)) return key;
    final match = summaries.where((s) => s.trackKey == key).toList();
    if (match.isEmpty) return key;
    final norm = normalizeTrackTitle(match.first.trackTitle);
    for (final s in summaries) {
      if (normalizeTrackTitle(s.trackTitle) == norm &&
          eventKeys.contains(s.trackKey)) {
        return s.trackKey;
      }
    }
    return key;
  }

  /// Primary lore tracks only (one key per normalized title; prefer eventful).
  static List<String> primaryTrackKeys(WorkLorePack pack) {
    final eventKeys = pack.events.map((e) => e.trackKey).toSet();
    final seenNorm = <String>{};
    final out = <String>[];

    void consider(String key, String title) {
      final norm = normalizeTrackTitle(title);
      final dedupeKey = norm.isEmpty ? key : norm;
      if (!seenNorm.add(dedupeKey)) return;
      out.add(key);
    }

    // Prefer summaries that have events, in album order.
    for (final s in pack.trackSummaries) {
      if (eventKeys.contains(s.trackKey)) {
        consider(s.trackKey, s.trackTitle);
      }
    }
    // Then other summaries (thin / remaster without events) if unique title.
    for (final s in pack.trackSummaries) {
      if (!eventKeys.contains(s.trackKey)) {
        consider(s.trackKey, s.trackTitle);
      }
    }
    // Orphan event keys.
    for (final key in eventKeys) {
      if (out.contains(key)) continue;
      consider(key, key);
    }
    return out;
  }

  /// Resolve span end for an event given the next cue on the same track.
  static int resolveEndMs(LoreTimelineEvent e, LoreTimelineEvent? next) {
    final start = e.atMs ?? 0;
    int? explicit = e.endMs ?? e.evidenceEndMs;
    if (explicit != null) {
      return math.max(explicit, start);
    }
    final nextAt = next?.atMs;
    final rampEnd = start + defaultRampMs;
    if (nextAt != null && nextAt > start) {
      return math.min(rampEnd, nextAt);
    }
    return rampEnd;
  }

  /// Apply prior primary tracks fully, then current-track spans with lerp.
  static LorePlaybackSnapshot project({
    required WorkLorePack pack,
    required String? trackKey,
    required int positionMs,
    String? focusCharacterId,
    String? trackTitle,
    int? trackIndex,
  }) {
    final focusId = focusCharacterId ?? pack.defaultFocusCharacterId;
    final base = pack.characterById(focusId);
    final resolved = resolveTrackKey(
      pack: pack,
      trackKey: trackKey,
      trackTitle: trackTitle,
      trackIndex: trackIndex,
    );

    String? resolvedTitle = trackTitle;
    if (resolved != null) {
      for (final s in pack.trackSummaries) {
        if (s.trackKey == resolved) {
          resolvedTitle = s.trackTitle;
          break;
        }
      }
    }

    if (base == null || resolved == null) {
      return LorePlaybackSnapshot(
        trackKey: trackKey,
        resolvedTrackKey: resolved,
        trackTitle: resolvedTitle,
        positionMs: positionMs,
        focusCharacterId: focusId,
        focusCharacter: base,
        projectedParams: base?.params ?? const [],
      );
    }

    final primary = primaryTrackKeys(pack);
    final currentOrd = primary.indexOf(resolved);
    final priorKeys = currentOrd < 0
        ? <String>{}
        : primary.sublist(0, currentOrd).toSet();

    final paramMap = <String, LoreParam>{
      for (final p in base.params) p.key: p,
    };
    final labelByKey = <String, String>{
      for (final p in base.params) p.key: p.label,
    };

    // Prior tracks: settle every span to its final `to`.
    for (final key in primary) {
      if (!priorKeys.contains(key)) continue;
      final events = _sortedTrackEvents(pack, key);
      for (var i = 0; i < events.length; i++) {
        final e = events[i];
        _applySettled(paramMap, e, focusId);
      }
    }

    final currentEvents = _sortedTrackEvents(pack, resolved);
    final revealed = <LoreTimelineEvent>[];
    final upcoming = <LoreTimelineEvent>[];
    LoreTimelineEvent? current;
    final spans = <LoreParamSpan>[];
    final active = <LoreParamSpan>[];
    final pulses = <LoreChangePulse>[];
    var timelineEnd = 0;

    for (var i = 0; i < currentEvents.length; i++) {
      final e = currentEvents[i];
      final next = i + 1 < currentEvents.length ? currentEvents[i + 1] : null;
      final start = e.atMs ?? 0;
      final end = resolveEndMs(e, next);
      timelineEnd = math.max(timelineEnd, end);

      final started = e.atMs == null || e.atMs! <= positionMs;
      if (started) {
        revealed.add(e);
        current = e;
      } else {
        upcoming.add(e);
      }

      if (e.characterId != null && e.characterId != focusId) continue;

      for (final d in e.deltas) {
        final span = LoreParamSpan(
          eventId: e.id,
          key: d.key,
          label: labelByKey[d.key] ?? d.key,
          startMs: start,
          endMs: end,
          from: d.from,
          to: d.to,
          numeric: d.isNumeric,
          kind: e.kind,
          title: e.title,
        );
        spans.add(span);

        if (positionMs < start) continue;

        if (d.isNumeric) {
          final value = _lerpDelta(d, start, end, positionMs);
          _setParam(paramMap, d.key, value, labelByKey);
          if (span.contains(positionMs)) active.add(span);
        } else {
          // Status / text: hold `from` during span, snap to `to` at end.
          if (positionMs < end && !span.isInstant) {
            _setParam(paramMap, d.key, d.from ?? d.to, labelByKey);
            active.add(span);
          } else {
            _setParam(paramMap, d.key, d.to, labelByKey);
            final snapAt = span.isInstant ? start : end;
            if ((positionMs - snapAt).abs() <= pulseWindowMs) {
              pulses.add(LoreChangePulse(
                key: d.key,
                from: d.from,
                to: d.to,
                eventId: e.id,
                atMs: snapAt,
              ));
            }
          }
        }
      }

      // Beat-only events (no deltas) still pulse title via currentEvent.
    }

    if (timelineEnd <= 0) {
      timelineEnd = math.max(positionMs + 60000, 60000);
    } else {
      timelineEnd = math.max(timelineEnd, positionMs + 1000);
    }

    final projected = paramMap.values.toList(growable: false);
    final focus = base.copyWith(params: projected);

    return LorePlaybackSnapshot(
      trackKey: trackKey,
      resolvedTrackKey: resolved,
      trackTitle: resolvedTitle,
      positionMs: positionMs,
      focusCharacterId: focusId,
      focusCharacter: focus,
      projectedParams: projected,
      currentEvent: current,
      revealedEvents: revealed,
      upcomingEvents: upcoming,
      trackSpans: spans,
      activeSpans: active,
      changePulses: pulses,
      trackTimelineEndMs: timelineEnd,
    );
  }

  static List<LoreTimelineEvent> _sortedTrackEvents(
    WorkLorePack pack,
    String trackKey,
  ) {
    return pack.events.where((e) => e.trackKey == trackKey).toList()
      ..sort((a, b) {
        final am = a.atMs ?? 1 << 30;
        final bm = b.atMs ?? 1 << 30;
        return am.compareTo(bm);
      });
  }

  static void _applySettled(
    Map<String, LoreParam> paramMap,
    LoreTimelineEvent e,
    String? focusId,
  ) {
    if (e.characterId != null && e.characterId != focusId) return;
    for (final d in e.deltas) {
      _setParam(paramMap, d.key, d.to);
    }
  }

  static dynamic _lerpDelta(
    LoreParamDelta d,
    int startMs,
    int endMs,
    int positionMs,
  ) {
    final from = LoreParamDelta.asNum(d.from)!;
    final to = LoreParamDelta.asNum(d.to)!;
    if (positionMs >= endMs || endMs <= startMs) return to;
    if (positionMs <= startMs) return from;
    final t = (positionMs - startMs) / (endMs - startMs);
    return from + (to - from) * t.clamp(0.0, 1.0);
  }

  static void _setParam(
    Map<String, LoreParam> paramMap,
    String key,
    dynamic value, [
    Map<String, String>? labels,
  ]) {
    final existing = paramMap[key];
    if (existing != null) {
      paramMap[key] =
          existing.copyWith(value: value, clearValue: value == null);
    } else {
      paramMap[key] = LoreParam(
        key: key,
        module: 'custom',
        label: labels?[key] ?? key,
        type: value is num ? LoreParamType.gauge : LoreParamType.text,
        value: value,
      );
    }
  }

  /// Per-track from→to arc for one character (detail Lore authoring view).
  /// Uses [primaryTrackKeys] so remasters don't duplicate rows.
  static List<LoreTrackParamArc> trackParamArcs({
    required WorkLorePack pack,
    required String characterId,
  }) {
    final labels = <String, String>{
      for (final c in pack.characters)
        for (final p in c.params) p.key: p.label,
    };
    final titles = <String, String>{
      for (final s in pack.trackSummaries) s.trackKey: s.trackTitle,
    };
    final indexes = <String, int>{
      for (final s in pack.trackSummaries) s.trackKey: s.trackIndex,
    };

    final arcs = <LoreTrackParamArc>[];
    for (final key in primaryTrackKeys(pack)) {
      final events = pack.events
          .where(
            (e) =>
                e.trackKey == key &&
                (e.characterId == null || e.characterId == characterId) &&
                e.deltas.isNotEmpty,
          )
          .toList()
        ..sort((a, b) => (a.atMs ?? 0).compareTo(b.atMs ?? 0));
      if (events.isEmpty) continue;

      // First seen `from`, last seen `to` per param key on this track.
      final firstFrom = <String, dynamic>{};
      final lastTo = <String, dynamic>{};
      for (final e in events) {
        for (final d in e.deltas) {
          firstFrom.putIfAbsent(d.key, () => d.from);
          lastTo[d.key] = d.to;
        }
      }

      final deltas = <LoreParamArcDelta>[];
      for (final entry in lastTo.entries) {
        final from = firstFrom[entry.key];
        final to = entry.value;
        if (from == to) continue;
        deltas.add(
          LoreParamArcDelta(
            key: entry.key,
            label: labels[entry.key] ?? entry.key,
            from: from,
            to: to,
          ),
        );
      }
      if (deltas.isEmpty) continue;

      arcs.add(
        LoreTrackParamArc(
          trackKey: key,
          trackTitle: titles[key] ?? key,
          trackIndex: indexes[key] ?? arcs.length,
          deltas: deltas,
        ),
      );
    }
    return arcs;
  }
}

/// One track's net param changes for a character.
class LoreTrackParamArc {
  final String trackKey;
  final String trackTitle;
  final int trackIndex;
  final List<LoreParamArcDelta> deltas;

  const LoreTrackParamArc({
    required this.trackKey,
    required this.trackTitle,
    required this.trackIndex,
    required this.deltas,
  });
}

class LoreParamArcDelta {
  final String key;
  final String label;
  final dynamic from;
  final dynamic to;

  const LoreParamArcDelta({
    required this.key,
    required this.label,
    required this.from,
    required this.to,
  });

  String get display =>
      '$label: ${_fmt(from)} → ${_fmt(to)}';

  static String _fmt(dynamic v) {
    if (v == null) return '—';
    if (v is num) {
      final d = v.toDouble();
      return d == d.roundToDouble() ? '${d.round()}' : d.toStringAsFixed(1);
    }
    return '$v';
  }
}
