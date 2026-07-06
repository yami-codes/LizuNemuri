import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/works/tag.dart';
import 'package:lizunemu/data/models/works/work_info.dart' as model;
import 'package:lizunemu/widgets/common/tag_chip.dart';
import 'package:lizunemu/widgets/detail/work_info_header.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/utils/tag_display_name.dart';
import 'package:lizunemu/utils/work_tag_search_navigation.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class WorkInfo extends StatelessWidget {
  final Work work;
  final model.WorkInfo? workInfo;
  final String displayTitle;
  final bool isTitleTranslated;
  final bool isTitleTranslating;
  final bool canRestoreOriginalTitle;
  final bool canShowTranslatedTitle;
  final VoidCallback? onTranslateTitle;
  final VoidCallback? onShowOriginalTitle;
  final VoidCallback? onShowTranslatedTitle;

  const WorkInfo({
    super.key,
    required this.work,
    this.workInfo,
    required this.displayTitle,
    this.isTitleTranslated = false,
    this.isTitleTranslating = false,
    this.canRestoreOriginalTitle = false,
    this.canShowTranslatedTitle = false,
    this.onTranslateTitle,
    this.onShowOriginalTitle,
    this.onShowTranslatedTitle,
  });

  AppSettingsService get _settings => GetIt.I<AppSettingsService>();

  String _tagLabel(Tag tag) => TagDisplayName.forTag(
        apiName: tag.name ?? '',
        i18n: tag.i18n,
        appLanguage: _settings.appLanguage,
      );

  void _onTagTap(BuildContext context, Tag tag) {
    final apiName = tag.name;
    if (apiName == null || apiName.isEmpty) return;

    AppLogger.debug(LogStrings.logTagTappedKeyword12029(apiName));
    openSearchWithTagToken(context, apiName);
  }

  Future<void> _onTagLongPress(BuildContext context, Tag tag) async {
    final apiName = tag.name;
    if (apiName == null || apiName.isEmpty) return;

    HapticFeedback.mediumImpact();
    final action = await showModalBottomSheet<_DetailTagFilterAction>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(Strings.filterTagInclude),
              subtitle: Text(_tagLabel(tag)),
              onTap: () => Navigator.pop(ctx, _DetailTagFilterAction.include),
            ),
            ListTile(
              leading: Icon(
                Icons.remove_circle_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(Strings.filterTagExclude),
              subtitle: Text(_tagLabel(tag)),
              onTap: () => Navigator.pop(ctx, _DetailTagFilterAction.exclude),
            ),
            const SizedBox(height: AppSpacing.space8),
          ],
        ),
      ),
    );

    if (action == null || !context.mounted) return;
    switch (action) {
      case _DetailTagFilterAction.include:
        openSearchWithTagToken(context, apiName);
      case _DetailTagFilterAction.exclude:
        openSearchWithExcludeTagToken(context, apiName);
    }
  }

  Widget _tagChip(BuildContext context, Tag tag) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTagTap(context, tag),
      onLongPress: () => _onTagLongPress(context, tag),
      child: TagChip(
        text: _tagLabel(tag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkInfoHeader(
            work: work,
            workInfo: workInfo,
            displayTitle: displayTitle,
            isTitleTranslated: isTitleTranslated,
            isTitleTranslating: isTitleTranslating,
            canRestoreOriginalTitle: canRestoreOriginalTitle,
            canShowTranslatedTitle: canShowTranslatedTitle,
            onTranslateTitle: onTranslateTitle,
            onShowOriginalTitle: onShowOriginalTitle,
            onShowTranslatedTitle: onShowTranslatedTitle,
          ),
          const SizedBox(height: 8),
          if (work.tags != null && work.tags!.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: work.tags!.map((tag) => _tagChip(context, tag)).toList(),
            ),
        ],
      ),
    );
  }
}

enum _DetailTagFilterAction { include, exclude }
