import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/lore_state_projector.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';
import 'package:lizunemu/widgets/lore/lore_track_timeline.dart';

/// Full-screen player lore surface: live params + subtitle + roomy timeline.
class PlayerLorePanel extends StatefulWidget {
  final WorkLorePack pack;
  final PlayerViewModel player;
  final String? trackKey;
  final String? trackTitle;
  final int? trackIndex;

  const PlayerLorePanel({
    super.key,
    required this.pack,
    required this.player,
    this.trackKey,
    this.trackTitle,
    this.trackIndex,
  });

  @override
  State<PlayerLorePanel> createState() => _PlayerLorePanelState();
}

class _PlayerLorePanelState extends State<PlayerLorePanel> {
  String? _focusOverrideId;

  @override
  Widget build(BuildContext context) {
    if (!widget.pack.hasLore) {
      return Center(child: Text(Strings.loreEmptyHint));
    }

    return ListenableBuilder(
      listenable: widget.player,
      builder: (context, _) {
        final positionMs = widget.player.position?.inMilliseconds ?? 0;
        final snapshot = LoreStateProjector.project(
          pack: widget.pack,
          trackKey: widget.trackKey,
          trackTitle: widget.trackTitle,
          trackIndex: widget.trackIndex,
          positionMs: positionMs,
          focusCharacterId: _focusOverrideId,
        );
        final scheme = Theme.of(context).colorScheme;
        final focus = snapshot.focusCharacter;
        final allParams = _visibleParams(
          snapshot.projectedParams,
          activeKeys: snapshot.activeSpans.map((s) => s.key).toSet(),
        );
        final pulseKeys = snapshot.changePulses.map((p) => p.key).toSet();
        final activeKeys = snapshot.activeSpans.map((s) => s.key).toSet();

        final subtitle = widget.player.currentSubtitle;
        final original = subtitle == null
            ? null
            : widget.player.originalSubtitleTextAt(subtitle.index);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space12,
            AppSpacing.space8,
            AppSpacing.space12,
            AppSpacing.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.pack.characters.length > 1) ...[
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in widget.pack.characters)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: AppSpacing.space8,
                          ),
                          child: ChoiceChip(
                            label: Text(c.name),
                            selected:
                                (snapshot.focusCharacterId ?? '') == c.id,
                            onSelected: (_) {
                              setState(() => _focusOverrideId = c.id);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
              ],
              // Current lyric line — keeps lore tab useful while listening.
              _CurrentSubtitleBanner(
                primary: subtitle?.text,
                secondary: original,
              ),
              const SizedBox(height: AppSpacing.space8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      focus?.name ?? Strings.lorePlayerParamsTitle,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (snapshot.currentEvent != null)
                    Flexible(
                      child: Text(
                        snapshot.currentEvent!.title,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              if (allParams.isEmpty)
                Text(
                  Strings.loreEmptyHint,
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                // Scrollable so secret ontology can show *all* chips without
                // starving the timeline.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 148),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: AppSpacing.space8,
                      runSpacing: AppSpacing.space8,
                      children: [
                        for (final p in allParams)
                          LoreParamCompactChip(
                            key: ValueKey('chip-${p.key}'),
                            label: p.speculative
                                ? '${p.label} · ${Strings.loreSpeculativeBadge}'
                                : p.label,
                            valueText: _valueLabel(p),
                            gauge: p.gaugeValue,
                            accent: _accent(p),
                            active: activeKeys.contains(p.key),
                            pulse: pulseKeys.contains(p.key),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.space12),
              Text(
                Strings.lorePlayerTimeline,
                style: AppTextStyles.titleMedium.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Expanded(
                child: LoreTrackTimeline(
                  snapshot: snapshot,
                  player: widget.player,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Full Lore tab shows every projected param once secrets are revealed;
  /// otherwise speculative keys stay hidden. Active/pinned float first.
  List<LoreParam> _visibleParams(
    List<LoreParam> params, {
    required Set<String> activeKeys,
  }) {
    final source = widget.pack.explicitRevealed
        ? params
        : params.where((p) => !p.speculative).toList();
    final active = <LoreParam>[];
    final pinned = <LoreParam>[];
    final rest = <LoreParam>[];
    for (final p in source) {
      if (activeKeys.contains(p.key)) {
        active.add(p);
      } else if (p.hudPinned) {
        pinned.add(p);
      } else {
        rest.add(p);
      }
    }
    return [...active, ...pinned, ...rest];
  }

  String _valueLabel(LoreParam param) {
    final gauge = param.gaugeValue;
    if (gauge != null) {
      return '${gauge.round()}${param.unit ?? ''}';
    }
    final v = param.value;
    if (v == null) return '—';
    return '$v${param.unit ?? ''}';
  }

  Color? _accent(LoreParam p) {
    if (p.accentHex != null && p.accentHex!.startsWith('#')) {
      final hex = p.accentHex!.substring(1);
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    return null;
  }
}

class _CurrentSubtitleBanner extends StatelessWidget {
  final String? primary;
  final String? secondary;

  const _CurrentSubtitleBanner({
    this.primary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasLine = primary != null && primary!.trim().isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (secondary != null && secondary!.trim().isNotEmpty) ...[
              Text(
                secondary!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              hasLine ? primary! : Strings.noLyrics,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: hasLine ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
