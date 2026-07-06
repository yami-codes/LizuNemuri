import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/data/models/works/tag.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/utils/tag_display_name.dart';

typedef TagFilterNameCallback = void Function(String apiTagName);

class WorkTagsPanel extends StatelessWidget {
  const WorkTagsPanel({
    super.key,
    required this.work,
    this.onTagInclude,
    this.onTagExclude,
  });

  final Work work;
  final TagFilterNameCallback? onTagInclude;
  final TagFilterNameCallback? onTagExclude;

  AppSettingsService get _settings => GetIt.I<AppSettingsService>();

  String _label(Tag tag) => TagDisplayName.forTag(
        apiName: tag.name ?? '',
        i18n: tag.i18n,
        appLanguage: _settings.appLanguage,
      );

  Future<void> _onTagLongPress(BuildContext context, Tag tag) async {
    final apiName = tag.name;
    if (apiName == null || apiName.isEmpty) return;
    if (onTagInclude == null && onTagExclude == null) return;

    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<_TagFilterAction>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(Strings.filterTagInclude),
              subtitle: Text(_label(tag)),
              onTap: () => Navigator.pop(ctx, _TagFilterAction.include),
            ),
            ListTile(
              leading: Icon(Icons.remove_circle_outline,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text(Strings.filterTagExclude),
              subtitle: Text(_label(tag)),
              onTap: () => Navigator.pop(ctx, _TagFilterAction.exclude),
            ),
            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );

    if (action == null || !context.mounted) return;
    switch (action) {
      case _TagFilterAction.include:
        onTagInclude?.call(apiName);
      case _TagFilterAction.exclude:
        onTagExclude?.call(apiName);
    }
  }

  void _onTagTap(BuildContext context, Tag tag) {
    final apiName = tag.name;
    if (apiName == null || apiName.isEmpty || onTagInclude == null) return;
    onTagInclude!(apiName);
  }

  Widget _tagChip(BuildContext context, Tag tag) {
    final interactive = onTagInclude != null || onTagExclude != null;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label(tag),
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (!interactive) return child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTagTap(context, tag),
      onLongPress: () => _onTagLongPress(context, tag),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        if (work.circle?.name != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              work.circle?.name ?? '',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[700],
              ),
            ),
          ),
        ...?work.vas?.map((va) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                va['name'] ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[700],
                ),
              ),
            )),
        if (work.hasSubtitle == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              Strings.subtitleChip,
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[700],
              ),
            ),
          ),
        ...work.tags?.map((tag) => _tagChip(context, tag)).toList() ?? [],
      ],
    );
  }
}

enum _TagFilterAction { include, exclude }
