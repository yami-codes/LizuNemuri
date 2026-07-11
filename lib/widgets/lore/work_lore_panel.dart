import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/lore_state_projector.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_content_level.dart';
import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';
import 'package:lizunemu/core/lore/models/work_lore_pack.dart';
import 'package:lizunemu/core/lore/work_lore_service.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/presentation/viewmodels/detail_viewmodel.dart';
import 'package:lizunemu/presentation/viewmodels/work_lore_viewmodel.dart';
import 'package:lizunemu/widgets/lore/lore_character_editor_sheet.dart';
import 'package:lizunemu/widgets/lore/lore_hud_pins_sheet.dart';
import 'package:lizunemu/widgets/lore/lore_merge_sheet.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Work Detail lore authoring surface.
class WorkLorePanel extends StatelessWidget {
  final List<DownloadPair> pairs;
  final Files? files;

  const WorkLorePanel({
    super.key,
    required this.pairs,
    this.files,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkLoreViewModel>(
      builder: (context, vm, _) {
        if (vm.loading && vm.pack == null) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.space24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.generating) {
          return _GeneratingCard(vm: vm);
        }

        if (!vm.hasLore) {
          return _EmptyLore(vm: vm, pairs: pairs, files: files);
        }

        final pack = vm.pack!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                child: Text(
                  vm.error!,
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            _ActionBar(vm: vm, pairs: pairs, files: files),
            const SizedBox(height: AppSpacing.space16),
            _SynopsisCard(pack: pack),
            const SizedBox(height: AppSpacing.space16),
            _CharactersSection(vm: vm, pack: pack),
            const SizedBox(height: AppSpacing.space16),
            _TrackSummariesSection(
              vm: vm,
              pack: pack,
              pairs: pairs,
              files: files,
            ),
            const SizedBox(height: AppSpacing.space16),
            _TimelineSection(pack: pack),
            const SizedBox(height: AppSpacing.space16),
            _SeedNotesSection(vm: vm, pack: pack),
            const SizedBox(height: AppSpacing.space24),
          ],
        );
      },
    );
  }
}

class _GeneratingCard extends StatelessWidget {
  final WorkLoreViewModel vm;
  const _GeneratingCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String stageLabel = Strings.loreGenerating;
    if (vm.progressStage.startsWith('cast')) {
      stageLabel = Strings.loreProgressCast;
    } else if (vm.progressStage.startsWith('secrets')) {
      stageLabel = Strings.loreProgressSecrets;
    } else if (vm.progressStage.startsWith('track')) {
      stageLabel = Strings.loreProgressTrack;
    } else if (vm.progressStage.startsWith('reconcile')) {
      stageLabel = Strings.loreProgressReconcile;
    } else if (vm.progressStage == 'done') {
      stageLabel = Strings.loreProgressDone;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          children: [
            Text(Strings.loreGenerating, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.space8),
            Text(stageLabel, style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.space12),
            LinearProgressIndicator(value: vm.progress.clamp(0.05, 1.0)),
            const SizedBox(height: AppSpacing.space12),
            TextButton(
              onPressed: vm.cancelGenerate,
              child: Text(Strings.loreCancel),
            ),
            Text(
              '${(vm.progress * 100).round()}%',
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLore extends StatelessWidget {
  final WorkLoreViewModel vm;
  final List<DownloadPair> pairs;
  final Files? files;

  const _EmptyLore({
    required this.vm,
    required this.pairs,
    this.files,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(Strings.loreEmptyHint, style: AppTextStyles.bodyMedium),
          if (vm.error != null) ...[
            const SizedBox(height: AppSpacing.space8),
            Text(
              vm.error!,
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space16),
          FilledButton.icon(
            onPressed: () => _onGenerate(context, vm, pairs, files),
            icon: const Icon(Icons.auto_awesome),
            label: Text(Strings.loreGenerate),
          ),
        ],
      ),
    );
  }
}

Future<void> _onGenerate(
  BuildContext context,
  WorkLoreViewModel vm,
  List<DownloadPair> pairs,
  Files? files,
) async {
  if (!await vm.hasApiKey()) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Strings.loreGenerateNeedApiKey)),
    );
    return;
  }
  await vm.generate(pairs: pairs, files: files);
  if (!context.mounted) return;
  if (vm.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Strings.loreFailed)),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final WorkLoreViewModel vm;
  final List<DownloadPair> pairs;
  final Files? files;

  const _ActionBar({
    required this.vm,
    required this.pairs,
    this.files,
  });

  @override
  Widget build(BuildContext context) {
    final pack = vm.pack!;
    return Wrap(
      spacing: AppSpacing.space8,
      runSpacing: AppSpacing.space8,
      children: [
        OutlinedButton(
          onPressed: () => vm.regenerate(
            section: LoreRegenSection.work,
            pairs: pairs,
            files: files,
          ),
          child: Text(Strings.loreRegenerateWork),
        ),
        OutlinedButton(
          onPressed: () => vm.generateSecrets(pairs: pairs, files: files),
          child: Text(Strings.loreGenerateSecrets),
        ),
        OutlinedButton(
          onPressed: () => vm.setExplicitRevealed(!pack.explicitRevealed),
          child: Text(
            pack.explicitRevealed
                ? Strings.loreHideExplicit
                : Strings.loreRevealExplicit,
          ),
        ),
        OutlinedButton(
          onPressed: () async {
            final json = await vm.exportPackJson();
            await Clipboard.setData(ClipboardData(text: json));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(Strings.loreExported)),
            );
          },
          child: Text(Strings.loreExportPack),
        ),
        OutlinedButton(
          onPressed: () async {
            final controller = TextEditingController();
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(Strings.loreImportPack),
                content: TextField(
                  controller: controller,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(Strings.loreCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(Strings.loreImportPack),
                  ),
                ],
              ),
            );
            if (ok == true && controller.text.trim().isNotEmpty) {
              await vm.importPackJson(controller.text);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(Strings.loreImported)),
              );
            }
          },
          child: Text(Strings.loreImportPack),
        ),
        OutlinedButton(
          onPressed: () async {
            final bytes = await vm.exportCcv2BatchZip();
            final file = await vm.writeBytesToTemp(
              'lizunemu_ccv2_${pack.workId}.zip',
              bytes,
            );
            await OpenFilex.open(file.path);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(Strings.loreExported)),
            );
          },
          child: Text(Strings.loreExportCcv2Batch),
        ),
        TextButton(
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(Strings.loreDelete),
                content: Text(Strings.loreDeleteConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(Strings.loreCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(Strings.loreDelete),
                  ),
                ],
              ),
            );
            if (ok == true) await vm.deleteLore();
          },
          child: Text(Strings.loreDelete),
        ),
        DropdownButton<LoreContentLevel>(
          value: pack.contentLevel,
          items: [
            DropdownMenuItem(
              value: LoreContentLevel.sfw,
              child: Text(Strings.loreContentSfw),
            ),
            DropdownMenuItem(
              value: LoreContentLevel.suggestive,
              child: Text(Strings.loreContentSuggestive),
            ),
            DropdownMenuItem(
              value: LoreContentLevel.explicit,
              child: Text(Strings.loreContentExplicit),
            ),
          ],
          onChanged: (v) {
            if (v != null) vm.setContentLevel(v);
          },
        ),
      ],
    );
  }
}

class _SynopsisCard extends StatelessWidget {
  final WorkLorePack pack;
  const _SynopsisCard({required this.pack});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Strings.loreSynopsis, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.space8),
            Text(
              pack.synopsis.isEmpty ? '—' : pack.synopsis,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CharactersSection extends StatelessWidget {
  final WorkLoreViewModel vm;
  final WorkLorePack pack;

  const _CharactersSection({required this.vm, required this.pack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Strings.loreCharacters, style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.space8),
        ...pack.characters.map((c) => _CharacterTile(vm: vm, pack: pack, character: c)),
      ],
    );
  }
}

class _CharacterTile extends StatelessWidget {
  final WorkLoreViewModel vm;
  final WorkLorePack pack;
  final LoreCharacter character;

  const _CharacterTile({
    required this.vm,
    required this.pack,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFocus = pack.defaultFocusCharacterId == character.id;
    final params = WorkLoreViewModel.visibleParams(character, pack);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    character.name,
                    style: AppTextStyles.titleMedium,
                  ),
                ),
                if (isFocus)
                  Chip(
                    label: Text(Strings.loreFocusCharacter),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: scheme.primaryContainer,
                  ),
              ],
            ),
            if (character.role != null)
              Text(character.role!, style: AppTextStyles.caption),
            if (character.personality != null) ...[
              const SizedBox(height: AppSpacing.space4),
              Text(character.personality!, style: AppTextStyles.bodyMedium),
            ],
            if (character.vaLinkProposed && !character.vaLinkConfirmed) ...[
              const SizedBox(height: AppSpacing.space8),
              Text(
                '${Strings.loreVaProposed}: ${character.voiceActorName ?? character.voiceActorId ?? ''}',
                style: AppTextStyles.caption,
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        vm.confirmVaLink(character.id, confirm: true),
                    child: Text(Strings.loreConfirmVaLink),
                  ),
                  TextButton(
                    onPressed: () =>
                        vm.confirmVaLink(character.id, confirm: false),
                    child: Text(Strings.loreRejectVaLink),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.space8),
            Text(
              Strings.loreParamBaseline,
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Wrap(
              spacing: AppSpacing.space8,
              runSpacing: AppSpacing.space4,
              children: params.take(8).map((p) => _ParamChip(param: p)).toList(),
            ),
            _CharacterTrackParamArc(pack: pack, characterId: character.id),
            const SizedBox(height: AppSpacing.space8),
            Wrap(
              spacing: AppSpacing.space8,
              children: [
                TextButton(
                  onPressed: () => vm.setFocusCharacter(character.id),
                  child: Text(Strings.loreFocusCharacter),
                ),
                TextButton(
                  onPressed: () => showLoreHudPinsSheet(
                    context,
                    vm: vm,
                    character: character,
                  ),
                  child: Text(Strings.loreHudPins),
                ),
                TextButton(
                  onPressed: () => showLoreCharacterEditor(
                    context,
                    vm: vm,
                    character: character,
                  ),
                  child: Text(Strings.loreEditCharacter),
                ),
                TextButton(
                  onPressed: () => vm.regenerate(
                    section: LoreRegenSection.character,
                    characterId: character.id,
                  ),
                  child: Text(Strings.loreRegenerateCharacter),
                ),
                TextButton(
                  onPressed: () async {
                    final choices = await showLoreMergeSheet(
                      context,
                      local: character,
                    );
                    if (choices == null) return;
                    await vm.promoteCharacter(
                      localCharacterId: character.id,
                      choices: choices,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(Strings.loreSaved)),
                    );
                  },
                  child: Text(Strings.lorePromoteGlobal),
                ),
                TextButton(
                  onPressed: () async {
                    final json = await vm.exportCcv2Json(character);
                    final file = await vm.writeExportToTemp(
                      '${character.name}_ccv2.json',
                      json,
                    );
                    await OpenFilex.open(file.path);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(Strings.loreExported)),
                    );
                  },
                  child: Text(Strings.loreExportCcv2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParamChip extends StatelessWidget {
  final LoreParam param;
  const _ParamChip({required this.param});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = param.value?.toString() ?? '—';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        '${param.label}: $value${param.speculative ? ' (${Strings.loreSpeculativeBadge})' : ''}',
        style: AppTextStyles.caption,
      ),
    );
  }
}

/// Per-track from→to param arc under a character card.
class _CharacterTrackParamArc extends StatelessWidget {
  final WorkLorePack pack;
  final String characterId;

  const _CharacterTrackParamArc({
    required this.pack,
    required this.characterId,
  });

  @override
  Widget build(BuildContext context) {
    final arcs = LoreStateProjector.trackParamArcs(
      pack: pack,
      characterId: characterId,
    );
    if (arcs.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings.loreParamChangesByTrack,
            style: AppTextStyles.labelMedium.copyWith(
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            Strings.loreParamChangesByTrackDesc,
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          ...arcs.map((arc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arc.trackTitle,
                    style: AppTextStyles.caption.copyWith(
                      color: scheme.primary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Wrap(
                    spacing: AppSpacing.space8,
                    runSpacing: AppSpacing.space4,
                    children: arc.deltas.map((d) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space8,
                          vertical: AppSpacing.space4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.55),
                          borderRadius: AppRadius.smAll,
                        ),
                        child: Text(
                          d.display,
                          style: AppTextStyles.caption.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TrackSummariesSection extends StatelessWidget {
  final WorkLoreViewModel vm;
  final WorkLorePack pack;
  final List<DownloadPair> pairs;
  final Files? files;

  const _TrackSummariesSection({
    required this.vm,
    required this.pack,
    required this.pairs,
    this.files,
  });

  @override
  Widget build(BuildContext context) {
    final focusId = pack.defaultFocusCharacterId;
    final arcsByKey = <String, LoreTrackParamArc>{
      if (focusId != null)
        for (final a in LoreStateProjector.trackParamArcs(
          pack: pack,
          characterId: focusId,
        ))
          a.trackKey: a,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Strings.loreTrackSummaries, style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.space8),
        ...pack.trackSummaries.map((t) {
          final arc = arcsByKey[t.trackKey];
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.space8),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(t.trackTitle),
                    subtitle: Text(
                      [
                        if (t.lowConfidence) Strings.loreLowConfidence,
                        t.summary,
                      ].where((e) => e.isNotEmpty).join('\n'),
                    ),
                    trailing: IconButton(
                      tooltip: Strings.loreRegenerateTrack,
                      icon: const Icon(Icons.refresh),
                      onPressed: () => vm.regenerate(
                        section: LoreRegenSection.track,
                        trackKey: t.trackKey,
                        pairs: pairs,
                        files: files,
                      ),
                    ),
                  ),
                  if (arc != null && arc.deltas.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space16,
                        0,
                        AppSpacing.space16,
                        AppSpacing.space8,
                      ),
                      child: Wrap(
                        spacing: AppSpacing.space8,
                        runSpacing: AppSpacing.space4,
                        children: arc.deltas.map((d) {
                          final scheme = Theme.of(context).colorScheme;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space8,
                              vertical: AppSpacing.space4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Text(
                              d.display,
                              style: AppTextStyles.caption.copyWith(
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final WorkLorePack pack;
  const _TimelineSection({required this.pack});

  @override
  Widget build(BuildContext context) {
    final byTrack = <String, List<LoreTimelineEvent>>{};
    final titles = <String, String>{
      for (final s in pack.trackSummaries) s.trackKey: s.trackTitle,
    };
    for (final e in pack.events) {
      byTrack.putIfAbsent(e.trackKey, () => []).add(e);
    }
    final order = LoreStateProjector.primaryTrackKeys(pack);
    final keys = [
      ...order.where(byTrack.containsKey),
      ...byTrack.keys.where((k) => !order.contains(k)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Strings.loreTimeline, style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.space8),
        if (keys.isEmpty)
          Text(Strings.loreNoEventsYet, style: AppTextStyles.caption)
        else
          ...keys.map((key) {
            final events = List<LoreTimelineEvent>.from(byTrack[key]!)
              ..sort((a, b) => (a.atMs ?? 0).compareTo(b.atMs ?? 0));
            final title = titles[key] ?? key;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  ...events.take(24).map((e) {
                    final ms = e.atMs;
                    final end = e.endMs ?? e.evidenceEndMs;
                    final time = ms == null
                        ? '—'
                        : '${_fmt(ms)}${end != null ? '–${_fmt(end)}' : ''}';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: SizedBox(
                        width: 72,
                        child: Text(time, style: AppTextStyles.caption),
                      ),
                      title: Text(e.title),
                      subtitle: Text(
                        [
                          e.detail,
                          if (e.evidenceQuote != null) '"${e.evidenceQuote}"',
                          if (e.speculative) Strings.loreSpeculativeBadge,
                        ].where((s) => s.isNotEmpty).join('\n'),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _fmt(int ms) {
    return '${(ms ~/ 60000).toString().padLeft(2, '0')}:'
        '${((ms % 60000) ~/ 1000).toString().padLeft(2, '0')}';
  }
}

class _SeedNotesSection extends StatelessWidget {
  final WorkLoreViewModel vm;
  final WorkLorePack pack;

  const _SeedNotesSection({required this.vm, required this.pack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Strings.loreSeedNotes, style: AppTextStyles.titleMedium),
        Text(Strings.loreSeedNotesHint, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.space8),
        ...pack.seedNotes.map((n) {
          return ListTile(
            title: Text(n.content),
            subtitle: Text('${n.scope.name} · ${n.keys.join(', ')}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => vm.deleteSeedNote(n.id),
            ),
          );
        }),
        TextButton.icon(
          onPressed: () async {
            final controller = TextEditingController();
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(Strings.loreAddSeedNote),
                content: TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(Strings.loreCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(Strings.loreAddSeedNote),
                  ),
                ],
              ),
            );
            if (ok == true && controller.text.trim().isNotEmpty) {
              await vm.upsertSeedNote(
                LoreSeedNote(
                  id: 'seed_${DateTime.now().millisecondsSinceEpoch}',
                  scope: LoreSeedScope.work,
                  content: controller.text.trim(),
                ),
              );
            }
          },
          icon: const Icon(Icons.add),
          label: Text(Strings.loreAddSeedNote),
        ),
      ],
    );
  }
}
