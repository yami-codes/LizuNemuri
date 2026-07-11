import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/presentation/viewmodels/work_lore_viewmodel.dart';

Future<void> showLoreHudPinsSheet(
  BuildContext context, {
  required WorkLoreViewModel vm,
  required LoreCharacter character,
}) async {
  final pinned = character.params.where((p) => p.hudPinned).map((p) => p.key).toSet();

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(Strings.loreHudPins),
                Text(Strings.loreHudPinsDesc),
                const SizedBox(height: AppSpacing.space12),
                Expanded(
                  child: ListView(
                    children: character.params.map((p) {
                      final on = pinned.contains(p.key);
                      return SwitchListTile(
                        title: Text(p.label),
                        subtitle: Text(p.key),
                        value: on,
                        onChanged: (v) {
                          setState(() {
                            if (v) {
                              pinned.add(p.key);
                            } else {
                              pinned.remove(p.key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    await vm.setHudPins(character.id, pinned);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(Strings.loreSaved),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
