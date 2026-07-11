import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/global_character_service.dart';
import 'package:lizunemu/core/lore/models/global_character.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';

Future<List<LoreFieldMergeChoice>?> showLoreMergeSheet(
  BuildContext context, {
  required LoreCharacter local,
  GlobalCharacter? global,
}) async {
  final choices = GlobalCharacterService.defaultMergeChoices(
    local: local,
    global: global,
  );

  return showModalBottomSheet<List<LoreFieldMergeChoice>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(Strings.loreMergeTitle),
                const SizedBox(height: AppSpacing.space12),
                Expanded(
                  child: ListView.builder(
                    itemCount: choices.length,
                    itemBuilder: (_, i) {
                      final c = choices[i];
                      return SwitchListTile(
                        title: Text(c.fieldKey),
                        subtitle: Text(
                          c.preferLocal
                              ? Strings.loreMergePreferLocal
                              : Strings.loreMergePreferGlobal,
                        ),
                        value: c.preferLocal,
                        onChanged: (v) {
                          setState(() {
                            choices[i] = LoreFieldMergeChoice(
                              fieldKey: c.fieldKey,
                              localValue: c.localValue,
                              globalValue: c.globalValue,
                              preferLocal: v,
                            );
                          });
                        },
                      );
                    },
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, List.of(choices)),
                  child: Text(Strings.lorePromoteGlobal),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<String?> showPickGlobalCharacterSheet(BuildContext context) async {
  final service = GetIt.instance<GlobalCharacterService>();
  final list = await service.listAll();
  if (!context.mounted) return null;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      if (list.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Text(Strings.loreGlobalEmpty),
        );
      }
      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          final g = list[i];
          return ListTile(
            title: Text(g.name),
            subtitle: Text(g.id),
            onTap: () => Navigator.pop(ctx, g.id),
          );
        },
      );
    },
  );
}
