import 'package:lizunemu/presentation/models/age_rating_filter.dart';
import 'package:lizunemu/presentation/models/work_list_filter_preset.dart';

class FilterState {
  final String orderField;
  final bool isDescending;
  final List<String> includeTags;
  final AgeRatingFilter ageRating;

  const FilterState({
    this.orderField = 'create_date',
    this.isDescending = true,
    this.includeTags = const [],
    this.ageRating = AgeRatingFilter.all,
  });

  bool get hasTagOrAgeFilter =>
      includeTags.isNotEmpty || ageRating.isActive;

  bool get showSortDirection => orderField != 'random';

  String get sortValue => orderField == 'random' ? 'desc' : (isDescending ? 'desc' : 'asc');

  WorkListFilterPreset get activePreset =>
      WorkListFilterPresetX.fromOrder(
        orderField: orderField,
        isDescending: isDescending,
      );

  FilterState copyWith({
    String? orderField,
    bool? isDescending,
    List<String>? includeTags,
    AgeRatingFilter? ageRating,
  }) {
    return FilterState(
      orderField: orderField ?? this.orderField,
      isDescending: isDescending ?? this.isDescending,
      includeTags: includeTags ?? this.includeTags,
      ageRating: ageRating ?? this.ageRating,
    );
  }

  FilterState copyWithPreset(WorkListFilterPreset preset) {
    return copyWith(
      orderField: preset.orderField,
      isDescending: preset.isDescending,
    );
  }

  // Serialization
  Map<String, dynamic> toJson() => {
        'orderField': orderField,
        'isDescending': isDescending,
        'includeTags': includeTags,
        'ageRating': ageRating.name,
      };

  // Deserialization
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

    return FilterState(
      orderField: json['orderField'] ?? 'create_date',
      isDescending: json['isDescending'] ?? true,
      includeTags: includeTags,
      ageRating: ageRating,
    );
  }
} 