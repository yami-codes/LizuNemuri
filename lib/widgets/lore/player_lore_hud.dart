import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/lore_state_projector.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';

/// Compact playback-synced lore HUD. Hidden when [pack] has no lore.
class PlayerLoreHud extends StatelessWidget {
  final WorkLorePack pack;
  final PlayerViewModel player;
  final String? trackKey;
  final String? focusOverrideId;

  const PlayerLoreHud({
    super.key,
    required this.pack,
    required this.player,
    this.trackKey,
    this.focusOverrideId,
  });

  @override
  Widget build(BuildContext context) {
    if (!pack.hasLore) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final positionMs = player.position?.inMilliseconds ?? 0;
        final snapshot = LoreStateProjector.project(
          pack: pack,
          trackKey: trackKey,
          positionMs: positionMs,
          focusCharacterId: focusOverrideId,
        );
        final pinnedParams = snapshot.projectedParams
            .where((p) => p.hudPinned)
            .take(6)
            .toList();
        final pins = pinnedParams.isNotEmpty
            ? pinnedParams
            : snapshot.projectedParams
                .where((p) => p.type == LoreParamType.gauge)
                .take(4)
                .toList();

        final scheme = Theme.of(context).colorScheme;
        return Material(
          color: scheme.surface.withValues(alpha: 0.72),
          borderRadius: AppRadius.mdAll,
          child: InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: () => _openTimeline(context, snapshot),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        snapshot.focusCharacter?.name ?? Strings.lorePlayerHud,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.timeline,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  ...pins.map((p) => _GaugeRow(param: p)),
                  if (snapshot.currentEvent != null) ...[
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      snapshot.currentEvent!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openTimeline(BuildContext context, LorePlaybackSnapshot snapshot) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (_, controller) {
            final events = snapshot.revealedEvents.reversed.toList();
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(AppSpacing.space16),
              children: [
                Text(
                  Strings.lorePlayerTimeline,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.space8),
                if (events.isEmpty)
                  Text(Strings.loreNoEventsYet)
                else
                  ...events.map((e) {
                    final ms = e.atMs ?? 0;
                    final time =
                        '${(ms ~/ 60000).toString().padLeft(2, '0')}:${((ms % 60000) ~/ 1000).toString().padLeft(2, '0')}';
                    return ListTile(
                      dense: true,
                      leading: Text(time),
                      title: Text(e.title),
                      subtitle: Text(e.detail),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }
}

class _GaugeRow extends StatelessWidget {
  final LoreParam param;
  const _GaugeRow({required this.param});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gauge = param.gaugeValue;
    Color? accent;
    if (param.accentHex != null && param.accentHex!.startsWith('#')) {
      final hex = param.accentHex!.substring(1);
      final value = int.tryParse(hex, radix: 16);
      if (value != null) {
        accent = Color(0xFF000000 | value);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  param.label,
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                gauge != null
                    ? '${gauge.round()}${param.unit ?? ''}'
                    : '${param.value ?? '—'}',
                style: AppTextStyles.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (gauge != null)
            ClipRRect(
              borderRadius: AppRadius.fullAll,
              child: LinearProgressIndicator(
                value: (gauge / 100).clamp(0.0, 1.0),
                minHeight: 4,
                color: accent ?? scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
        ],
      ),
    );
  }
}
