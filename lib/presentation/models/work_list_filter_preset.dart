import 'package:flutter/material.dart';
import 'package:lizunemu/common/constants/strings.dart';

/// Quick list filter presets aligned with Eara [SearchFilterOption] sort chips.
/// Maps to asmr.one `order` + `sort` query params on `/works` and `/search`.
enum WorkListFilterPreset {
  latest,
  release,
  sales,
  priceHigh,
  rating,
  allAges,
  random,
  review,
  priceLow,
  releaseAsc,
  oldest,
  rjDesc,
  rjAsc,
  myRating,
}

extension WorkListFilterPresetX on WorkListFilterPreset {
  String get orderField => switch (this) {
        WorkListFilterPreset.latest ||
        WorkListFilterPreset.oldest =>
          'create_date',
        WorkListFilterPreset.release ||
        WorkListFilterPreset.releaseAsc =>
          'release',
        WorkListFilterPreset.sales => 'dl_count',
        WorkListFilterPreset.priceHigh ||
        WorkListFilterPreset.priceLow =>
          'price',
        WorkListFilterPreset.rating => 'rate_average_2dp',
        WorkListFilterPreset.review => 'review_count',
        WorkListFilterPreset.allAges => 'nsfw',
        WorkListFilterPreset.random => 'random',
        WorkListFilterPreset.rjDesc ||
        WorkListFilterPreset.rjAsc =>
          'id',
        WorkListFilterPreset.myRating => 'rating',
      };

  bool get isDescending => switch (this) {
        WorkListFilterPreset.priceLow ||
        WorkListFilterPreset.releaseAsc ||
        WorkListFilterPreset.oldest ||
        WorkListFilterPreset.rjAsc =>
          false,
        _ => true,
      };

  bool get showSortDirection => orderField != 'random';

  IconData get icon => switch (this) {
        WorkListFilterPreset.latest => Icons.schedule_outlined,
        WorkListFilterPreset.release => Icons.fiber_new_outlined,
        WorkListFilterPreset.sales => Icons.emoji_events_outlined,
        WorkListFilterPreset.priceHigh ||
        WorkListFilterPreset.priceLow =>
          Icons.payments_outlined,
        WorkListFilterPreset.rating => Icons.star_outline,
        WorkListFilterPreset.review => Icons.rate_review_outlined,
        WorkListFilterPreset.allAges => Icons.child_care_outlined,
        WorkListFilterPreset.random => Icons.shuffle,
        WorkListFilterPreset.oldest => Icons.history,
        WorkListFilterPreset.releaseAsc => Icons.event_outlined,
        WorkListFilterPreset.rjDesc ||
        WorkListFilterPreset.rjAsc =>
          Icons.tag_outlined,
        WorkListFilterPreset.myRating => Icons.thumb_up_alt_outlined,
      };

  String get label => switch (this) {
        WorkListFilterPreset.latest => Strings.filterPresetLatest,
        WorkListFilterPreset.release => Strings.filterPresetRelease,
        WorkListFilterPreset.sales => Strings.filterPresetSales,
        WorkListFilterPreset.priceHigh => Strings.filterPresetPrice,
        WorkListFilterPreset.priceLow => Strings.sortPriceAsc,
        WorkListFilterPreset.rating => Strings.filterPresetRating,
        WorkListFilterPreset.review => Strings.filterOrderReview,
        WorkListFilterPreset.allAges => Strings.filterOrderAllAges,
        WorkListFilterPreset.random => Strings.filterOrderRandom,
        WorkListFilterPreset.oldest => Strings.sortOldest,
        WorkListFilterPreset.releaseAsc => Strings.sortReleaseAsc,
        WorkListFilterPreset.rjDesc => Strings.sortRjDesc,
        WorkListFilterPreset.rjAsc => Strings.sortRjAsc,
        WorkListFilterPreset.myRating => Strings.filterOrderMyRating,
      };

  /// Chips always visible in the quick row (Eara primary scope options).
  static const primaryPresets = [
    WorkListFilterPreset.latest,
    WorkListFilterPreset.release,
    WorkListFilterPreset.sales,
    WorkListFilterPreset.priceHigh,
    WorkListFilterPreset.rating,
    WorkListFilterPreset.allAges,
    WorkListFilterPreset.random,
  ];

  /// Extra sorts exposed via the "More" sheet.
  static const secondaryPresets = [
    WorkListFilterPreset.review,
    WorkListFilterPreset.oldest,
    WorkListFilterPreset.releaseAsc,
    WorkListFilterPreset.priceLow,
    WorkListFilterPreset.rjDesc,
    WorkListFilterPreset.rjAsc,
    WorkListFilterPreset.myRating,
  ];

  static WorkListFilterPreset fromOrder({
    required String orderField,
    required bool isDescending,
  }) {
    for (final preset in WorkListFilterPreset.values) {
      if (preset.orderField == orderField &&
          preset.isDescending == isDescending) {
        return preset;
      }
    }
    return WorkListFilterPreset.latest;
  }
}
