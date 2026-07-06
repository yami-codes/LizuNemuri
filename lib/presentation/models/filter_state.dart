import 'package:lizunemu/presentation/models/age_rating_filter.dart';
import 'package:lizunemu/presentation/models/work_list_filter_preset.dart';
import 'package:lizunemu/presentation/models/search_command_parser.dart';
import 'package:lizunemu/presentation/models/tag_filter_helper.dart';

class FilterState {
  final String orderField;
  final bool isDescending;
  final List<String> includeTags;
  final List<String> excludeTags;
  final AgeRatingFilter ageRating;

  const FilterState({
    this.orderField = 'create_date',
    this.isDescending = true,
    this.includeTags = const [],
    this.excludeTags = const [],
    this.ageRating = AgeRatingFilter.all,
  });

  bool get hasTagOrAgeFilter =>
      includeTags.isNotEmpty ||
      excludeTags.isNotEmpty ||
      ageRating.isActive;

  bool get hasCommandFilter => hasTagOrAgeFilter;

  bool get showSortDirection => orderField != 'random';

  String get sortValue =>
      orderField == 'random' ? 'desc' : (isDescending ? 'desc' : 'asc');

  WorkListFilterPreset get activePreset =>
      WorkListFilterPresetX.fromOrder(
        orderField: orderField,
        isDescending: isDescending,
      );

  FilterState copyWith({
    String? orderField,
    bool? isDescending,
    List<String>? includeTags,
    List<String>? excludeTags,
    AgeRatingFilter? ageRating,
  }) {
    return FilterState(
      orderField: orderField ?? this.orderField,
      isDescending: isDescending ?? this.isDescending,
      includeTags: includeTags ?? this.includeTags,
      excludeTags: excludeTags ?? this.excludeTags,
      ageRating: ageRating ?? this.ageRating,
    );
  }

  FilterState copyWithPreset(WorkListFilterPreset preset) {
    return copyWith(
      orderField: preset.orderField,
      isDescending: preset.isDescending,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderField': orderField,
        'isDescending': isDescending,
        'includeTags': includeTags,
        'excludeTags': excludeTags,
        'ageRating': ageRating.name,
      };

  factory FilterState.fromJson(Map<String, dynamic> json) {
    final ageRaw = json['ageRating'] as String?;
    final ageRating = AgeRatingFilter.values.firstWhere(
      (v) => v.name == ageRaw,
      orElse: () => AgeRatingFilter.all,
    );
    final tagsRaw = json['includeTags'];
    final includeTags = tagsRaw is List
        ? tagsRaw.map((e) => e.toString()).toList()
        : const <String>[];
    final excludeRaw = json['excludeTags'];
    final excludeTags = excludeRaw is List
        ? excludeRaw.map((e) => e.toString()).toList()
        : const <String>[];

    return FilterState(
      orderField: json['orderField'] ?? 'create_date',
      isDescending: json['isDescending'] ?? true,
      includeTags: includeTags,
      excludeTags: excludeTags,
      ageRating: ageRating,
    );
  }

  /// Merge chip state with parsed command tokens (deduped).
  FilterState mergeParsedTokens(Iterable<String> tokens) {
    final parsed = SearchCommandParser.parseTagNames(tokens);
    var next = this;
    for (final t in parsed.include) {
      next = TagFilterHelper.addInclude(next, t);
    }
    for (final t in parsed.exclude) {
      next = TagFilterHelper.addExclude(next, t);
    }
    return next;
  }
} 