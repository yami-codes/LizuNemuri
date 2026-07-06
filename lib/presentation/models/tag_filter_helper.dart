import 'package:lizunemu/presentation/models/age_rating_filter.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';
import 'package:lizunemu/presentation/models/search_command_parser.dart';

/// Mutations for include/exclude tag lists on [FilterState].
class TagFilterHelper {
  TagFilterHelper._();

  static FilterState addInclude(FilterState state, String apiName) {
    final trimmed = apiName.trim();
    if (trimmed.isEmpty) return state;
    final include = List<String>.from(state.includeTags);
    final exclude = List<String>.from(state.excludeTags)..remove(trimmed);
    if (!include.contains(trimmed)) include.add(trimmed);
    return state.copyWith(includeTags: include, excludeTags: exclude);
  }

  static FilterState addExclude(FilterState state, String apiName) {
    final trimmed = apiName.trim();
    if (trimmed.isEmpty) return state;
    final exclude = List<String>.from(state.excludeTags);
    final include = List<String>.from(state.includeTags)..remove(trimmed);
    if (!exclude.contains(trimmed)) exclude.add(trimmed);
    return state.copyWith(includeTags: include, excludeTags: exclude);
  }

  static FilterState removeInclude(FilterState state, String apiName) {
    final include = List<String>.from(state.includeTags)..remove(apiName);
    return state.copyWith(includeTags: include);
  }

  static FilterState removeExclude(FilterState state, String apiName) {
    final exclude = List<String>.from(state.excludeTags)..remove(apiName);
    return state.copyWith(excludeTags: exclude);
  }

  static List<String> tokensFromFilterState(FilterState state) {
    final tokens = <String>[
      for (final t in state.includeTags)
        SearchCommandParser.includeTagToken(t),
      for (final t in state.excludeTags)
        SearchCommandParser.excludeTagToken(t),
      if (state.ageRating.searchToken != null) state.ageRating.searchToken!,
    ];
    return tokens;
  }
}
