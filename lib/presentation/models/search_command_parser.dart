/// Parses and composes asmr.one `$command:value$` search tokens.
class SearchCommandParser {
  SearchCommandParser._();

  /// Known command keys (without `$` delimiters).
  static const commandKeys = [
    'tag',
    '-tag',
    'tagw',
    '-tagw',
    'circle',
    '-circle',
    'va',
    '-va',
    'duration',
    '-duration',
    'rate',
    'price',
    '-price',
    'sell',
    'age',
    '-age',
    'lang',
    '-lang',
  ];

  static final _tokenPattern = RegExp(
    r'\$(-?(?:tagw?|circle|va|duration|rate|price|sell|age|lang)):([^$]*)\$',
  );

  /// Split [input] into complete tokens and remaining free text / draft.
  static ParsedSearchCommand parse(String input) {
    final tokens = <String>[];
    for (final match in _tokenPattern.allMatches(input)) {
      tokens.add(match.group(0)!);
    }
    var remainder = input.replaceAll(_tokenPattern, ' ');
    remainder = remainder.replaceAll(RegExp(r'\s+'), ' ').trim();
    return ParsedSearchCommand(tokens: tokens, remainder: remainder);
  }

  /// Join tokens and optional free text for `/search/{keyword}`.
  static String compose({
    Iterable<String> tokens = const [],
    String freeText = '',
  }) {
    final parts = [...tokens];
    final text = freeText.trim();
    if (text.isNotEmpty) parts.add(text);
    return parts.join(' ');
  }

  /// Whether [input] contains any command token.
  static bool hasCommandTokens(String input) =>
      _tokenPattern.hasMatch(input);

  /// Extract include / exclude tag API names from tokens.
  static ({List<String> include, List<String> exclude}) parseTagNames(
    Iterable<String> tokens,
  ) {
    final include = <String>[];
    final exclude = <String>[];
    for (final raw in tokens) {
      final match = _tokenPattern.firstMatch(raw);
      if (match == null) continue;
      final key = match.group(1)!;
      final value = match.group(2)!.trim();
      if (value.isEmpty) continue;
      if (key == 'tag' || key == 'tagw') {
        if (!include.contains(value)) include.add(value);
      } else if (key == '-tag' || key == '-tagw') {
        if (!exclude.contains(value)) exclude.add(value);
      }
    }
    return (include: include, exclude: exclude);
  }

  static String includeTagToken(String apiName) => '\$tag:$apiName\$';

  static String excludeTagToken(String apiName) => '\$-tag:$apiName\$';
}

class ParsedSearchCommand {
  const ParsedSearchCommand({
    required this.tokens,
    required this.remainder,
  });

  final List<String> tokens;
  final String remainder;

  String compose() => SearchCommandParser.compose(
        tokens: tokens,
        freeText: remainder,
      );
}
