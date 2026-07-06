import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/data/models/tags/tag_item.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/screens/browse/widgets/browse_search_bar.dart';
import 'package:lizunemu/utils/i18n_name_resolver.dart';
import 'package:lizunemu/utils/user_facing_error.dart';

/// Multi-select tag picker for asmr.one `$tag:name$` search filters.
class TagPickerSheet extends StatefulWidget {
  final List<String> initialSelected;

  const TagPickerSheet({
    super.key,
    this.initialSelected = const [],
  });

  /// Opens the sheet and returns the chosen API tag names, or null if dismissed.
  static Future<List<String>?> show(
    BuildContext context, {
    List<String> initialSelected = const [],
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TagPickerSheet(initialSelected: initialSelected),
    );
  }

  @override
  State<TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<TagPickerSheet> {
  final _api = GetIt.I<ApiService>();
  List<TagItem> _allTags = [];
  late Set<String> _selected;
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelected);
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tags = await _api.getTags();
      tags.sort((a, b) => (b.count ?? 0).compareTo(a.count ?? 0));
      if (!mounted) return;
      setState(() {
        _allTags = tags;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = userFacingError(e);
        _loading = false;
      });
    }
  }

  List<TagItem> get _visibleTags {
    if (_query.isEmpty) return _allTags;
    final lower = _query.toLowerCase();
    return _allTags.where((tag) {
      final name = tag.name?.toLowerCase() ?? '';
      final localized = I18nNameResolver.searchableNames(tag.i18n)
          .map((n) => n.toLowerCase())
          .any((n) => n.contains(lower));
      return name.contains(lower) || localized;
    }).toList();
  }

  void _toggle(String apiName) {
    setState(() {
      if (_selected.contains(apiName)) {
        _selected.remove(apiName);
      } else {
        _selected.add(apiName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageMobile,
                    AppSpacing.space8,
                    AppSpacing.pageMobile,
                    AppSpacing.space4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          Strings.filterPickTags,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_selected.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(_selected.clear),
                          child: Text(Strings.filterClearTags),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageMobile,
                  ),
                  child: BrowseSearchBar(
                    hintText: Strings.browseSearchTagsHint,
                    onChanged: (q) => setState(() => _query = q),
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Expanded(child: _buildBody(context, scrollController)),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.pageMobile),
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _selected.toList()),
                    child: Text(
                      Strings.filterApplyTags(_selected.length),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.space8),
            ElevatedButton(
              onPressed: _loadTags,
              child: Text(Strings.retry),
            ),
          ],
        ),
      );
    }

    final tags = _visibleTags;
    if (tags.isEmpty) {
      return Center(child: Text(Strings.browseEmptyTags));
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final apiName = tag.name ?? '';
        if (apiName.isEmpty) return const SizedBox.shrink();

        final displayName = I18nNameResolver.resolve(
          tag.i18n,
          locale: Localizations.localeOf(context),
          fallback: apiName,
        );
        final selected = _selected.contains(apiName);

        return CheckboxListTile(
          value: selected,
          onChanged: (_) => _toggle(apiName),
          title: Text(displayName),
          subtitle: tag.count != null
              ? Text('${tag.count}')
              : null,
          secondary: selected
              ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
              : null,
        );
      },
    );
  }
}
