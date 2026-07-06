import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/presentation/models/age_rating_filter.dart';
import 'package:lizunemu/presentation/models/filter_state.dart';
import 'package:lizunemu/presentation/models/work_list_query_builder.dart';

void main() {
  group('WorkListQueryBuilder', () {
    test('builds tag tokens space-separated', () {
      expect(
        WorkListQueryBuilder.buildSearchKeyword(
          includeTags: ['ASMR', '舔耳'],
        ),
        r'$tag:ASMR$ $tag:舔耳$',
      );
    });

    test('builds age tokens', () {
      expect(
        WorkListQueryBuilder.buildSearchKeyword(
          ageRating: AgeRatingFilter.general,
        ),
        r'$age:general$',
      );
      expect(
        WorkListQueryBuilder.buildSearchKeyword(
          ageRating: AgeRatingFilter.adult,
        ),
        r'$age:adult$',
      );
    });

    test('combines tags, age, and free text', () {
      expect(
        WorkListQueryBuilder.buildSearchKeyword(
          textKeyword: 'sleep',
          includeTags: ['ASMR'],
          ageRating: AgeRatingFilter.general,
        ),
        r'$tag:ASMR$ $age:general$ sleep',
      );
    });

    test('requiresSearchEndpoint when tags or age active', () {
      expect(
        WorkListQueryBuilder.requiresSearchEndpoint(const FilterState()),
        isFalse,
      );
      expect(
        WorkListQueryBuilder.requiresSearchEndpoint(
          const FilterState(includeTags: ['ASMR']),
        ),
        isTrue,
      );
      expect(
        WorkListQueryBuilder.requiresSearchEndpoint(
          const FilterState(excludeTags: ['AI']),
        ),
        isTrue,
      );
      expect(
        WorkListQueryBuilder.requiresSearchEndpoint(
          const FilterState(ageRating: AgeRatingFilter.adult),
        ),
        isTrue,
      );
    });

    test('builds exclude tag tokens', () {
      expect(
        WorkListQueryBuilder.buildSearchKeyword(
          excludeTags: ['AI'],
        ),
        r'$-tag:AI$',
      );
    });

    test('FilterState round-trips tags and age via JSON', () {
      const state = FilterState(
        includeTags: ['ASMR', '巨乳/爆乳'],
        ageRating: AgeRatingFilter.general,
      );
      final restored = FilterState.fromJson(state.toJson());
      expect(restored.includeTags, state.includeTags);
      expect(restored.ageRating, state.ageRating);
    });
  });
}
