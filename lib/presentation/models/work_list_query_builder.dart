import 'package:lizunemu/presentation/models/age_rating_filter.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';
import 'package:lizunemu/presentation/models/search_command_parser.dart';

/// Builds asmr.one `/search/{keyword}` path segments from filters + optional text.
class WorkListQueryBuilder {
  WorkListQueryBuilder._();

  /// Compose space-separated search keyword: command tokens then free text.
  static String buildSearchKeyword({
    String textKeyword = '',
    List<String> includeTags = const [],
    List<String> excludeTags = const [],
    AgeRatingFilter ageRating = AgeRatingFilter.all,
    List<String> extraTokens = const [],
  }) {
    final parts = <String>[];

    for (final token in extraTokens) {
      if (token.trim().isNotEmpty) parts.add(token);
    }

    for (final tag in includeTags) {
      final trimmed = tag.trim();
      if (trimmed.isEmpty) continue;
      final token = SearchCommandParser.includeTagToken(trimmed);
      if (!parts.contains(token)) parts.add(token);
    }

    for (final tag in excludeTags) {
      final trimmed = tag.trim();
      if (trimmed.isEmpty) continue;
      final token = SearchCommandParser.excludeTagToken(trimmed);
      if (!parts.contains(token)) parts.add(token);
    }

    final ageToken = ageRating.searchToken;
    if (ageToken != null && !parts.contains(ageToken)) {
      parts.add(ageToken);
    }

    final parsed = SearchCommandParser.parse(textKeyword);
    for (final token in parsed.tokens) {
      if (!parts.contains(token)) parts.add(token);
    }

    if (parsed.remainder.isNotEmpty) {
      parts.add(parsed.remainder);
    }

    return parts.join(' ');
  }

  /// Build keyword purely from [FilterState] command fields.
  static String fromFilterState(FilterState state, {String freeText = ''}) =>
      buildSearchKeyword(
        textKeyword: freeText,
        includeTags: state.includeTags,
        excludeTags: state.excludeTags,
        ageRating: state.ageRating,
      );

  /// Whether list fetch must use `/search` instead of `/works`.
  static bool requiresSearchEndpoint(FilterState state) =>
      state.includeTags.isNotEmpty ||
      state.excludeTags.isNotEmpty ||
      state.ageRating.isActive;
}
