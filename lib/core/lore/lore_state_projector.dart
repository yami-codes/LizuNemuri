import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';

/// Bidirectional projection of character params from timeline events.
class LorePlaybackSnapshot {
  final String? trackKey;
  final int positionMs;
  final String? focusCharacterId;
  final LoreCharacter? focusCharacter;
  final List<LoreParam> projectedParams;
  final LoreTimelineEvent? currentEvent;
  final List<LoreTimelineEvent> revealedEvents;
  final List<LoreTimelineEvent> upcomingEvents;

  const LorePlaybackSnapshot({
    this.trackKey,
    required this.positionMs,
    this.focusCharacterId,
    this.focusCharacter,
    this.projectedParams = const [],
    this.currentEvent,
    this.revealedEvents = const [],
    this.upcomingEvents = const [],
  });
}

class LoreStateProjector {
  /// Apply all events for [trackKey] with `atMs <= positionMs` (and track-level
  /// events with null atMs treated as end-of-track / always-on for that track
  /// when [includeNullTimestamp] is true).
  static LorePlaybackSnapshot project({
    required WorkLorePack pack,
    required String? trackKey,
    required int positionMs,
    String? focusCharacterId,
  }) {
    final focusId = focusCharacterId ?? pack.defaultFocusCharacterId;
    final base = pack.characterById(focusId);
    if (base == null || trackKey == null) {
      return LorePlaybackSnapshot(
        trackKey: trackKey,
        positionMs: positionMs,
        focusCharacterId: focusId,
        focusCharacter: base,
        projectedParams: base?.params ?? const [],
      );
    }

    final trackEvents = pack.events
        .where((e) => e.trackKey == trackKey)
        .toList()
      ..sort((a, b) {
        final am = a.atMs ?? 1 << 30;
        final bm = b.atMs ?? 1 << 30;
        return am.compareTo(bm);
      });

    final revealed = <LoreTimelineEvent>[];
    final upcoming = <LoreTimelineEvent>[];
    LoreTimelineEvent? current;

    for (final e in trackEvents) {
      final t = e.atMs;
      if (t == null || t <= positionMs) {
        revealed.add(e);
        current = e;
      } else {
        upcoming.add(e);
      }
    }

    final paramMap = <String, LoreParam>{
      for (final p in base.params) p.key: p,
    };

    for (final e in revealed) {
      if (e.characterId != null && e.characterId != focusId) continue;
      for (final d in e.deltas) {
        final existing = paramMap[d.key];
        if (existing != null) {
          paramMap[d.key] = existing.copyWith(value: d.to);
        } else {
          paramMap[d.key] = LoreParam(
            key: d.key,
            module: 'custom',
            label: d.key,
            type: LoreParamType.text,
            value: d.to,
          );
        }
      }
    }

    final projected = paramMap.values.toList(growable: false);
    final focus = base.copyWith(params: projected);

    return LorePlaybackSnapshot(
      trackKey: trackKey,
      positionMs: positionMs,
      focusCharacterId: focusId,
      focusCharacter: focus,
      projectedParams: projected,
      currentEvent: current,
      revealedEvents: revealed,
      upcomingEvents: upcoming,
    );
  }
}
