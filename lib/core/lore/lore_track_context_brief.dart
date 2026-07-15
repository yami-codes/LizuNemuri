import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart'
    show LoreSeedNote;

/// Local prior-context blob for the next track/secrets prompt (no LLM).
class LoreTrackContextBrief {
  LoreTrackContextBrief._();

  static const int synopsisCap = 400;
  static const int summaryCap = 500;
  static const int maxPriorSummaries = 2;
  static const int maxEventTitles = 6;

  static String clip(String? text, int max) {
    final t = (text ?? '').trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }

  /// Build a compact "Prior context" string for prompts.
  static String build({
    required String synopsis,
    required List<LoreTrackSummary> completedSummaries,
    required List<LoreTimelineEvent> completedEvents,
    required Map<String, Map<String, dynamic>> carryState,
    bool slimCarry = true,
  }) {
    final buf = StringBuffer();
    final syn = clip(synopsis, synopsisCap);
    if (syn.isNotEmpty) {
      buf.writeln('Synopsis: $syn');
    }

    final prior = completedSummaries.length > maxPriorSummaries
        ? completedSummaries.sublist(
            completedSummaries.length - maxPriorSummaries,
          )
        : completedSummaries;
    for (final s in prior) {
      final body = clip(s.summary, summaryCap);
      if (body.isEmpty) continue;
      buf.writeln('Prior track [${s.trackTitle}]: $body');
    }

    final titles = <String>[];
    for (final e in completedEvents.reversed) {
      if (titles.length >= maxEventTitles) break;
      final title = e.title.trim();
      if (title.isEmpty) continue;
      final tag = e.speculative ? 'spec' : 'ev';
      titles.add('$tag:${e.kind}:$title');
    }
    if (titles.isNotEmpty) {
      buf.writeln('Recent event titles: ${titles.reversed.join(' | ')}');
    }

    final carry = slimCarry ? slimCarryMap(carryState) : carryState;
    if (carry.isNotEmpty) {
      buf.writeln('Carry end-state: $carry');
    }
    return buf.toString().trim();
  }

  /// Prefer pinned / non-empty keys; drop nullish noise.
  static Map<String, Map<String, dynamic>> slimCarryMap(
    Map<String, Map<String, dynamic>> carry,
  ) {
    final out = <String, Map<String, dynamic>>{};
    for (final entry in carry.entries) {
      final slim = <String, dynamic>{};
      for (final kv in entry.value.entries) {
        final v = kv.value;
        if (v == null) continue;
        if (v is String && v.trim().isEmpty) continue;
        slim[kv.key] = v;
      }
      if (slim.isNotEmpty) out[entry.key] = slim;
    }
    return out;
  }

  /// Settle character param maps from completed events on [priorTrackKeys].
  static Map<String, Map<String, dynamic>> settleCarryFromEvents({
    required Map<String, Map<String, dynamic>> baselines,
    required List<LoreTimelineEvent> events,
    required Set<String> priorTrackKeys,
  }) {
    final carry = <String, Map<String, dynamic>>{
      for (final e in baselines.entries)
        e.key: Map<String, dynamic>.from(e.value),
    };
    final sorted = [...events]..sort((a, b) {
        final ta = a.trackKey.compareTo(b.trackKey);
        if (ta != 0) return ta;
        return (a.atMs ?? 0).compareTo(b.atMs ?? 0);
      });
    for (final e in sorted) {
      if (!priorTrackKeys.contains(e.trackKey)) continue;
      final cid = e.characterId;
      if (cid == null || cid.isEmpty) {
        // Apply to all characters when unscoped.
        for (final id in carry.keys) {
          _applyDeltas(carry[id]!, e);
        }
      } else {
        carry.putIfAbsent(cid, () => <String, dynamic>{});
        _applyDeltas(carry[cid]!, e);
      }
    }
    return carry;
  }

  static void _applyDeltas(
    Map<String, dynamic> map,
    LoreTimelineEvent e,
  ) {
    for (final d in e.deltas) {
      map[d.key] = d.to ?? d.from;
    }
  }

  /// Whether reconcile is worth a main-model call.
  static bool shouldReconcile({
    required int characterCount,
    required List<LoreTrackSummary> summaries,
    required List<LoreSeedNote> seedNotes,
  }) {
    if (characterCount > 2) return true;
    if (seedNotes.isNotEmpty) return true;
    for (final s in summaries) {
      if (s.lowConfidence) return true;
    }
    return false;
  }
}
