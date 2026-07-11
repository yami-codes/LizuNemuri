import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/presentation/viewmodels/work_lore_viewmodel.dart';

Future<void> showLoreCharacterEditor(
  BuildContext context, {
  required WorkLoreViewModel vm,
  required LoreCharacter character,
}) async {
  final name = TextEditingController(text: character.name);
  final appearance = TextEditingController(text: character.appearance ?? '');
  final personality = TextEditingController(text: character.personality ?? '');
  final notes = TextEditingController(text: character.notes ?? '');
  final relationship =
      TextEditingController(text: character.relationshipToListener ?? '');

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.space16,
          right: AppSpacing.space16,
          top: AppSpacing.space8,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpacing.space16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(Strings.loreEditCharacter),
              const SizedBox(height: AppSpacing.space12),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: appearance,
                decoration: const InputDecoration(labelText: 'Appearance'),
                maxLines: 3,
              ),
              TextField(
                controller: personality,
                decoration: const InputDecoration(labelText: 'Personality'),
                maxLines: 3,
              ),
              TextField(
                controller: relationship,
                decoration:
                    const InputDecoration(labelText: 'Relationship to listener'),
                maxLines: 2,
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.space16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(Strings.loreSaved),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (saved == true) {
    await vm.updateCharacter(
      character.copyWith(
        name: name.text.trim().isEmpty ? character.name : name.text.trim(),
        appearance: appearance.text.trim().isEmpty ? null : appearance.text.trim(),
        personality:
            personality.text.trim().isEmpty ? null : personality.text.trim(),
        relationshipToListener: relationship.text.trim().isEmpty
            ? null
            : relationship.text.trim(),
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      ),
    );
  }
}
