/// Age rating filter for asmr.one search syntax (`$age:general$` / `$age:adult$`).
enum AgeRatingFilter {
  all,
  general,
  adult,
}

extension AgeRatingFilterX on AgeRatingFilter {
  /// Search token for this rating, or null when no age filter is applied.
  String? get searchToken => switch (this) {
        AgeRatingFilter.all => null,
        AgeRatingFilter.general => r'$age:general$',
        AgeRatingFilter.adult => r'$age:adult$',
      };

  bool get isActive => this != AgeRatingFilter.all;
}
