import 'package:flutter/material.dart';
import 'package:xuro/data/models/works/work.dart';
import 'package:xuro/data/models/works/tag.dart';
import 'package:xuro/data/models/works/work_info.dart' as model;
import 'package:xuro/widgets/common/tag_chip.dart';
import 'package:xuro/widgets/detail/work_info_header.dart';
import 'package:xuro/utils/i18n_name_resolver.dart';
import 'package:xuro/utils/logger.dart';
import 'package:xuro/common/constants/log_strings.dart';

class WorkInfo extends StatelessWidget {
  final Work work;
  final model.WorkInfo? workInfo;

  const WorkInfo({
    super.key,
    required this.work,
    this.workInfo,
  });

  String _getLocalizedTagName(BuildContext context, Tag tag) {
    return I18nNameResolver.resolve(
      tag.i18n,
      locale: Localizations.localeOf(context),
      fallback: tag.name ?? '',
    );
  }

  void _onTagTap(BuildContext context, Tag tag) {
    final keyword = tag.name ?? '';
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkInfoHeader(work: work, workInfo: workInfo),
          const SizedBox(height: 8),
          if (work.tags != null && work.tags!.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: work.tags!
                  .map((tag) => TagChip(
                        text: _getLocalizedTagName(context, tag),
                        onTap: () => _onTagTap(context, tag),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
