import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/presentation/models/search_command_parser.dart';
import 'package:lizunemu/presentation/models/search_command_suggestions.dart';

void main() {
  group('SearchCommandParser', () {
    test('parses tag and age tokens with free text', () {
      final parsed = SearchCommandParser.parse(
        r'$tag:Binaural$ $age:r15$ sleep',
      );
      expect(parsed.tokens, [
        r'$tag:Binaural$',
        r'$age:r15$',
      ]);
      expect(parsed.remainder, 'sleep');
      expect(
        parsed.compose(),
        r'$tag:Binaural$ $age:r15$ sleep',
      );
    });

    test('extracts include and exclude tag names', () {
      final names = SearchCommandParser.parseTagNames([
        r'$tag:ASMR$',
        r'$-tag:AI$',
      ]);
      expect(names.include, ['ASMR']);
      expect(names.exclude, ['AI']);
    });

    test('builds exclude tag token', () {
      expect(
        SearchCommandParser.excludeTagToken('AI'),
        r'$-tag:AI$',
      );
    });
  });

  group('SearchCommandSuggestor', () {
    test('suggests commands after dollar sign', () {
      final items = SearchCommandSuggestor.suggest(
        draft: r'$ta',
        cursor: 3,
      );
      expect(items.any((s) => s.title.contains('tag')), isTrue);
    });

    test('suggests age values after prefix', () {
      final items = SearchCommandSuggestor.suggest(
        draft: r'$age:',
        cursor: 5,
      );
      expect(items.any((s) => s.title.contains('general')), isTrue);
      expect(items.any((s) => s.title.contains('adult')), isTrue);
    });

    test('promotes complete token from draft', () {
      final result = SearchCommandSuggestor.extractCompleteTokens(
        tokens: const [],
        draft: r'hello $tag:ASMR$ world',
      );
      expect(result.tokens, [r'$tag:ASMR$']);
      expect(result.draft, 'hello world');
    });
  });
}
