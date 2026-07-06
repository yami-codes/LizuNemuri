import 'package:lizunemu/presentation/models/age_rating_filter.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';

/// Builds asmr.one `/search/{keyword}` path segments from filters + optional text.
class WorkListQueryBuilder {
  WorkListQueryBuilder._();

  /// Compose space-separated search keyword: tag tokens, age token, then free text.
  static String buildSearchKeyword({
    String textKeyword = '',
    List<String> includeTags = const [],
    AgeRatingFilter ageRating = AgeRatingFilter.all,
  }) {
    final parts = <String>[];

    for (final tag in includeTags) {
      final trimmed = tag.trim();
      if (trimmed.isEmpty) continue;
      parts.add('\$tag:$trimmed\$');
    }

    final ageToken = ageRating.searchToken;
    if (ageToken != null) {
      parts.add(ageToken);
    }

    final text = textKeyword.trim();
    if (text.isNotEmpty) {
      parts.add(text);
    }

    return parts.join(' ');
  }

  /// Whether list fetch must use `/search` instead of `/works`.
  static bool requiresSearchEndpoint(FilterState state) =>
      state.includeTags.isNotEmpty || state.ageRating.isActive;
}
