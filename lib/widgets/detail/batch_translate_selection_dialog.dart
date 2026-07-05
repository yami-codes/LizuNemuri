import 'package:flutter/material.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/core/theme/app_spacing.dart';
import 'package:xuro/presentation/viewmodels/detail_viewmodel.dart';

/// Result from the bulk-translate checklist.
class BatchTranslateSelectionResult {
  final List<DownloadPair> pairs;
  final bool translateTitle;

  const BatchTranslateSelectionResult({
    required this.pairs,
    required this.translateTitle,
  });
}

/// Checklist to pick which tracks to pre-translate; shows per-track cache badges.
class BatchTranslateSelectionDialog extends StatefulWidget {
  final Future<List<TranslateSelectionItem>> Function() loadItems;
  final Future<int> Function() cachedCount;
  final String? workTitle;
  final Future<bool> Function()? isTitleCached;

  const BatchTranslateSelectionDialog({
    super.key,
    required this.loadItems,
    required this.cachedCount,
    this.workTitle,
    this.isTitleCached,
  });

  @override
  State<BatchTranslateSelectionDialog> createState() =>
      _BatchTranslateSelectionDialogState();
}

class _BatchTranslateSelectionDialogState
    extends State<BatchTranslateSelectionDialog> {
  List<TranslateSelectionItem>? _items;
  final Set<int> _selected = {};
  int _savedCount = 0;
  bool _translateTitle = true;
  bool _titleCached = false;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.loadItems();
      final saved = await widget.cachedCount();
      final titleCached = widget.isTitleCached != null
          ? await widget.isTitleCached!()
          : false;
      if (!mounted) return;
      setState(() {
        _items = items;
        _savedCount = saved;
        _titleCached = titleCached;
        _translateTitle = widget.workTitle?.trim().isNotEmpty == true;
        _selected.addAll(List.generate(items.length, (i) => i));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toggleAll(bool select) {
    final items = _items;
    if (items == null) return;
    setState(() {
      _selected
        ..clear()
        ..addAll(select ? List.generate(items.length, (i) => i) : const []);
    });
  }

  List<DownloadPair> _selectedPairs() {
    final items = _items!;
    return [for (final i in _selected) items[i].pair];
  }

  BatchTranslateSelectionResult _selectionResult() {
    return BatchTranslateSelectionResult(
      pairs: _selectedPairs(),
      translateTitle: _translateTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AlertDialog(
        title: Text(Strings.batchTranslateTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.space12),
            Text(Strings.batchTranslateLoading),
          ],
        ),
      );
    }

    if (_error != null) {
      return AlertDialog(
        title: Text(Strings.batchTranslateTitle),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Strings.confirm),
          ),
        ],
      );
    }

    final items = _items!;
    if (items.isEmpty) {
      return AlertDialog(
        title: Text(Strings.batchTranslateTitle),
        content: Text(Strings.batchTranslateEmpty),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Strings.confirm),
          ),
        ],
      );
    }

    final cachedInList = items.where((e) => e.isCached).length;

    return AlertDialog(
      title: Text(Strings.batchTranslateTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Strings.batchTranslateCacheSummary(
                cachedInList,
                items.length,
                _savedCount,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.space8),
            Row(
              children: [
                TextButton(
                  onPressed: () => _toggleAll(true),
                  child: Text(Strings.batchTranslateSelectAll),
                ),
                TextButton(
                  onPressed: () => _toggleAll(false),
                  child: Text(Strings.batchTranslateDeselectAll),
                ),
              ],
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length +
                    (widget.workTitle?.trim().isNotEmpty == true ? 1 : 0),
                itemBuilder: (context, index) {
                  if (widget.workTitle?.trim().isNotEmpty == true &&
                      index == 0) {
                    return CheckboxListTile(
                      value: _translateTitle,
                      onChanged: (v) =>
                          setState(() => _translateTitle = v ?? false),
                      title: Text(Strings.batchTranslateIncludeTitle),
                      subtitle: Text(
                        _titleCached
                            ? Strings.batchTranslateCachedBadge
                            : widget.workTitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    );
                  }
                  final itemIndex =
                      widget.workTitle?.trim().isNotEmpty == true
                          ? index - 1
                          : index;
                  final item = items[itemIndex];
                  return CheckboxListTile(
                    value: _selected.contains(itemIndex),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(itemIndex);
                        } else {
                          _selected.remove(itemIndex);
                        }
                      });
                    },
                    title: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: item.isCached
                        ? Text(
                            Strings.batchTranslateCachedBadge,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : Text(Strings.batchTranslateNeedsTranslate),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Strings.downloadCancel),
        ),
        TextButton(
          onPressed: _selected.isEmpty && !_translateTitle
              ? null
              : () => Navigator.of(context).pop(_selectionResult()),
          child: Text(Strings.batchTranslateStart(
            _selected.length + (_translateTitle ? 1 : 0),
          )),
        ),
      ],
    );
  }
}
