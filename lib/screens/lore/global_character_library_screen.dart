import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/lore/global_character_service.dart';
import 'package:lizunemu/core/lore/models/global_character.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';
import 'package:lizunemu/widgets/common/back_leading.dart';

class GlobalCharacterLibraryScreen extends StatefulWidget {
  const GlobalCharacterLibraryScreen({super.key});

  @override
  State<GlobalCharacterLibraryScreen> createState() =>
      _GlobalCharacterLibraryScreenState();
}

class _GlobalCharacterLibraryScreenState
    extends State<GlobalCharacterLibraryScreen> {
  late Future<List<GlobalCharacter>> _future;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = GetIt.instance<GlobalCharacterService>().listAll();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload([String? q]) {
    final service = GetIt.instance<GlobalCharacterService>();
    setState(() {
      _future = (q == null || q.trim().isEmpty)
          ? service.listAll()
          : service.search(q.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PoppableAppBar(title: Strings.loreGlobalLibrary),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: Strings.loreGlobalLibraryDesc,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _reload,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<GlobalCharacter>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return Center(child: Text(Strings.loreGlobalEmpty));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final g = list[i];
                    return ListTile(
                      title: Text(g.name, style: AppTextStyles.titleMedium),
                      subtitle: Text(
                        [
                          if (g.personality != null) g.personality!,
                          'works: ${g.linkedWorkIds.length}',
                        ].join('\n'),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await GetIt.instance<GlobalCharacterService>()
                              .delete(g.id);
                          _reload(_search.text);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
