import 'package:lizunemu/core/settings/app_language.dart';
import 'package:lizunemu/data/models/works/i18n.dart';
import 'package:lizunemu/presentation/models/search_command_parser.dart';
import 'package:lizunemu/utils/i18n_name_resolver.dart';
import 'package:lizunemu/utils/tag_display_name.dart';

/// One autocomplete row in the search command dropdown.
class SearchCommandSuggestion {
  const SearchCommandSuggestion({
    required this.insertText,
    required this.title,
    this.subtitle,
    this.completeToken = false,
  });

  /// Text inserted/replaced in the draft field.
  final String insertText;

  /// Primary label (command or value).
  final String title;

  /// Secondary hint (e.g. "Filter by tags").
  final String? subtitle;

  /// When true, [insertText] is a full `$…$` token ready to become a chip.
  final bool completeToken;
}

/// Context of an in-progress `$…` command at the cursor.
class SearchCommandContext {
  const SearchCommandContext({
    required this.triggerIndex,
    required this.commandKey,
    required this.partialValue,
    required this.hasColon,
  });

  final int triggerIndex;
  final String commandKey;
  final String partialValue;
  final bool hasColon;
}

class _TagSuggestEntry {
  const _TagSuggestEntry({
    required this.apiName,
    required this.displayLabel,
    required this.searchHaystack,
  });

  final String apiName;
  final String displayLabel;
  final List<String> searchHaystack;
}

class SearchCommandSuggestor {
  SearchCommandSuggestor._();

  static const _durationValues = [
    '20m',
    '30m',
    '40m',
    '50m',
    '1h',
    '1.2h',
  ];

  static const _priceValues = [
    '100',
    '300',
    '500',
    '700',
    '1000',
    '2000',
  ];

  static const _ageValues = [
    ('general', 'Only all-ages'),
    ('r15', 'Only R-15'),
    ('adult', 'Only R-18'),
  ];

  static const _commands = [
    ('tag', 'Filter by tags'),
    ('-tag', 'Exclude tags'),
    ('tagw', 'Include low-vote tags'),
    ('-tagw', 'Exclude low-vote tags'),
    ('circle', 'Filter by circles'),
    ('-circle', 'Exclude circles'),
    ('va', 'Filter by voice actors'),
    ('-va', 'Exclude voice actors'),
    ('duration', 'Duration greater than'),
    ('-duration', 'Duration less than'),
    ('rate', 'Rating greater than'),
    ('price', 'Price greater than'),
    ('-price', 'Price less than / exclude'),
    ('sell', 'Sales greater than'),
    ('age', 'Age rating'),
    ('-age', 'Exclude age rating'),
    ('lang', 'Language'),
    ('-lang', 'Exclude language'),
  ];

  static List<_TagSuggestEntry> _tagEntries({
    required List<String> tagNames,
    required Map<String, I18n> tagCatalog,
    required AppLanguage appLanguage,
  }) {
    return tagNames.map((apiName) {
      final i18n = tagCatalog[apiName];
      final display = TagDisplayName.forTag(
        apiName: apiName,
        i18n: i18n,
        appLanguage: appLanguage,
      );
      final haystack = <String>{
        apiName.toLowerCase(),
        display.toLowerCase(),
        ...I18nNameResolver.searchableNames(i18n)
            .map((name) => name.toLowerCase()),
      }.toList();
      return _TagSuggestEntry(
        apiName: apiName,
        displayLabel: display,
        searchHaystack: haystack,
      );
    }).toList();
  }

  static SearchCommandContext? contextAt(String text, int cursor) {
    if (cursor < 0) return null;
    final safeCursor = cursor.clamp(0, text.length);
    final before = text.substring(0, safeCursor);
    final trigger = before.lastIndexOf(r'$');
    if (trigger == -1) return null;

    final segment = before.substring(trigger);
    // Completed token already — no suggestions unless user starts a new `$`.
    if (RegExp(r'^\$-?\w+:[^$]*\$').hasMatch(segment)) return null;

    final body = segment.substring(1); // after leading $
    final colon = body.indexOf(':');
    if (colon == -1) {
      return SearchCommandContext(
        triggerIndex: trigger,
        commandKey: body.toLowerCase(),
        partialValue: '',
        hasColon: false,
      );
    }

    final key = body.substring(0, colon);
    final partial = body.substring(colon + 1);
    return SearchCommandContext(
      triggerIndex: trigger,
      commandKey: key.toLowerCase(),
      partialValue: partial,
      hasColon: true,
    );
  }

  static List<SearchCommandSuggestion> suggest({
    required String draft,
    required int cursor,
    List<String> tagNames = const [],
    Map<String, I18n> tagCatalog = const {},
    AppLanguage appLanguage = AppLanguage.en,
  }) {
    final ctx = contextAt(draft, cursor);
    if (ctx == null) return const [];

    if (!ctx.hasColon) {
      final prefix = ctx.commandKey;
      return _commands
          .where((c) => c.$1.startsWith(prefix))
          .map(
            (c) => SearchCommandSuggestion(
              insertText: '\$${c.$1}:',
              title: '\$${c.$1}:',
              subtitle: c.$2,
            ),
          )
          .toList();
    }

    final key = ctx.commandKey;
    final partial = ctx.partialValue.toLowerCase();

    if (key == 'tag' || key == '-tag' || key == 'tagw' || key == '-tagw') {
      final entries = _tagEntries(
        tagNames: tagNames,
        tagCatalog: tagCatalog,
        appLanguage: appLanguage,
      );
      return entries
          .where(
            (entry) => entry.searchHaystack.any((h) => h.contains(partial)),
          )
          .take(40)
          .map(
            (entry) => SearchCommandSuggestion(
              insertText: '\$$key:${entry.apiName}\$',
              title: entry.displayLabel,
              subtitle: '\$$key:${entry.apiName}\$',
              completeToken: true,
            ),
          )
          .toList();
    }

    if (key == 'age' || key == '-age') {
      return _ageValues
          .where((e) => e.$1.contains(partial))
          .map(
            (e) => SearchCommandSuggestion(
              insertText: '\$$key:${e.$1}\$',
              title: '\$$key:${e.$1}\$',
              subtitle: e.$2,
              completeToken: true,
            ),
          )
          .toList();
    }

    if (key == 'duration' || key == '-duration') {
      return _durationValues
          .where((v) => v.contains(partial))
          .map(
            (v) => SearchCommandSuggestion(
              insertText: '\$$key:$v\$',
              title: '\$$key:$v\$',
              subtitle: 'Unit: ${v.endsWith('h') ? 'hour' : 'minutes'}',
              completeToken: true,
            ),
          )
          .toList();
    }

    if (key == 'price' || key == '-price') {
      return _priceValues
          .where((v) => v.startsWith(partial))
          .map(
            (v) => SearchCommandSuggestion(
              insertText: '\$$key:$v\$',
              title: '\$$key:$v\$',
              subtitle: key.startsWith('-')
                  ? 'Reverse (filter/exclude)'
                  : 'Price > $v JPY',
              completeToken: true,
            ),
          )
          .toList();
    }

    return const [];
  }

  /// Apply [suggestion] to [draft] at [cursor]; returns new draft + cursor offset.
  static ({String draft, int cursor}) apply({
    required String draft,
    required int cursor,
    required SearchCommandSuggestion suggestion,
  }) {
    final ctx = contextAt(draft, cursor);
    if (ctx == null) {
      final next = '$draft${suggestion.insertText}';
      return (draft: next, cursor: next.length);
    }

    final before = draft.substring(0, ctx.triggerIndex);
    final after = draft.substring(cursor);
    final inserted = suggestion.insertText;
    final nextDraft = '$before$inserted$after';
    final nextCursor = before.length + inserted.length;
    return (draft: nextDraft, cursor: nextCursor);
  }

  /// Promote any complete `$…$` tokens from [draft] into [tokens]; return cleaned draft.
  static ({List<String> tokens, String draft}) extractCompleteTokens({
    required List<String> tokens,
    required String draft,
  }) {
    final parsed = SearchCommandParser.parse(draft);
    final merged = [...tokens, ...parsed.tokens];
    return (tokens: merged, draft: parsed.remainder);
  }
}
