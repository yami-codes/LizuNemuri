import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/works/tag.dart';
import 'package:lizunemu/utils/i18n_name_resolver.dart';

class WorkTagsPanel extends StatelessWidget {
  final Work work;

  const WorkTagsPanel({
    super.key,
    required this.work,
  });

  String _getLocalizedTagName(BuildContext context, Tag tag) {
    return I18nNameResolver.resolve(
      tag.i18n,
      locale: Localizations.localeOf(context),
      fallback: tag.name ?? '',
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
        ...work.tags
                ?.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getLocalizedTagName(context, tag),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ))
                .toList() ??
            [],
      ],
    );
  }
}
