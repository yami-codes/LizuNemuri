import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';

/// True when a track summary is worth keeping on resume (not an empty soft stub).
///
/// Mirrors queue `_applyOutcomesFromPack`: null OR empty text + lowConfidence
/// → incomplete (must re-LLM).
bool loreTrackSummaryIsComplete(LoreTrackSummary? summary) {
  if (summary == null) return false;
  if (summary.summary.trim().isEmpty && summary.lowConfidence) return false;
  return true;
}

/// Cast is reusable when at least one character exists.
bool lorePackHasReusableCast(WorkLorePack? pack) =>
    pack != null && pack.characters.isNotEmpty;

/// Track keys in [orderedTrackKeys] that already have a complete summary in [pack].
List<String> loreResumeSkipTrackKeys(
  WorkLorePack? pack,
  Iterable<String> orderedTrackKeys,
) {
  if (pack == null) return const [];
  final byKey = {
    for (final s in pack.trackSummaries) s.trackKey: s,
  };
  return [
    for (final key in orderedTrackKeys)
      if (loreTrackSummaryIsComplete(byKey[key])) key,
  ];
}

/// Summaries from [pack] for [orderedTrackKeys], keeping only complete ones,
/// in input order (incomplete keys omitted — caller will regenerate them).
List<LoreTrackSummary> loreResumeSeedSummaries(
  WorkLorePack? pack,
  Iterable<String> orderedTrackKeys,
) {
  if (pack == null) return const [];
  final byKey = {
    for (final s in pack.trackSummaries) s.trackKey: s,
  };
  final out = <LoreTrackSummary>[];
  for (final key in orderedTrackKeys) {
    final s = byKey[key];
    if (loreTrackSummaryIsComplete(s)) out.add(s!);
  }
  return out;
}

/// Events belonging to [keepTrackKeys] (complete tracks kept on resume).
List<LoreTimelineEvent> loreResumeSeedEvents(
  WorkLorePack? pack,
  Set<String> keepTrackKeys,
) {
  if (pack == null || keepTrackKeys.isEmpty) return const [];
  return [
    for (final e in pack.events)
      if (keepTrackKeys.contains(e.trackKey)) e,
  ];
}
