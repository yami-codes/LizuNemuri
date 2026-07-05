import 'package:flutter/material.dart';
import 'package:xuro/common/constants/strings.dart';
import 'package:xuro/data/models/works/work.dart';
import 'package:xuro/data/models/works/work_info.dart';
import 'package:xuro/widgets/common/tag_chip.dart';
import 'package:xuro/widgets/detail/work_stats_info.dart';
import 'package:xuro/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xuro/common/constants/log_strings.dart';

class WorkInfoHeader extends StatelessWidget {
  final Work work;
  final WorkInfo? workInfo;
  final String displayTitle;
  final bool isTitleTranslated;
  final bool isTitleTranslating;
  final bool canRestoreOriginalTitle;
  final bool canShowTranslatedTitle;
  final VoidCallback? onTranslateTitle;
  final VoidCallback? onShowOriginalTitle;
  final VoidCallback? onShowTranslatedTitle;

  const WorkInfoHeader({
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

  void _onTagTap(BuildContext context, String keyword) {
    if (keyword.isEmpty) return;

    AppLogger.debug(LogStrings.logTagTappedKeyword12029(keyword));
    Navigator.pushNamed(
      context,
      '/search',
      arguments: keyword,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final originalTitle = work.title?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isTitleTranslated ? cs.primary : null,
                        ),
                  ),
                  if (isTitleTranslated &&
                      originalTitle != null &&
                      originalTitle.isNotEmpty &&
                      originalTitle != displayTitle)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        originalTitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            if (onTranslateTitle != null)
              isTitleTranslating
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                    )
                  : PopupMenuButton<String>(
                      icon: Icon(
                        Icons.translate,
                        color: isTitleTranslated ? cs.primary : null,
                      ),
                      tooltip: Strings.llmTranslateTitle,
                      onSelected: (value) {
                        switch (value) {
                          case 'translate':
                            onTranslateTitle?.call();
                          case 'original':
                            onShowOriginalTitle?.call();
                          case 'translated':
                            onShowTranslatedTitle?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'translate',
                          child: Text(Strings.llmTranslateTitle),
                        ),
                        if (canRestoreOriginalTitle)
                          PopupMenuItem(
                            value: 'original',
                            child: Text(Strings.llmShowOriginalTitle),
                          ),
                        if (canShowTranslatedTitle &&
                            onShowTranslatedTitle != null)
                          PopupMenuItem(
                            value: 'translated',
                            child: Text(Strings.llmShowTranslatedTitle),
                          ),
                      ],
                    ),
          ],
        ),
        const SizedBox(height: 8),
        WorkStatsInfo(work: work),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (work.circle?.name != null)
              TagChip(
                text: work.circle?.name ?? '',
                backgroundColor: Colors.orange.withValues(alpha: 0.2),
                textColor: Colors.orange[700],
                onTap: () => _onTagTap(context, work.circle?.name ?? ''),
              ),
            ..._buildVaChips(context),
            if (work.hasSubtitle == true)
              TagChip(
                text: Strings.subtitleChip,
                backgroundColor: Colors.blue.withValues(alpha: 0.2),
                textColor: Colors.blue[700],
              ),
          ],
        ),
        if (workInfo != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              if (workInfo!.price != null)
                Text(
                  '${workInfo!.price} JPY',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              if (workInfo!.sourceUrl != null)
                GestureDetector(
                  onTap: () => _launchUrl(workInfo!.sourceUrl!),
                  child: Text(
                    'DLsite',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _buildVaChips(BuildContext context) {
    if (workInfo?.vas != null && workInfo!.vas!.isNotEmpty) {
      return workInfo!.vas!
          .map(
            (va) => TagChip(
              text: va.name ?? '',
              backgroundColor: Colors.green.withValues(alpha: 0.2),
              textColor: Colors.green[700],
              onTap: () => _onTagTap(context, va.name ?? ''),
            ),
          )
          .toList();
    }
    return work.vas
            ?.map(
              (va) => TagChip(
                text: va['name'] ?? '',
                backgroundColor: Colors.green.withValues(alpha: 0.2),
                textColor: Colors.green[700],
                onTap: () => _onTagTap(context, va['name'] ?? ''),
              ),
            )
            .toList() ??
        [];
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
