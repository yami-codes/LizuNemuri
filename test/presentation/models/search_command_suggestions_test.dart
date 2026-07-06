import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/settings/app_language.dart';
import 'package:lizunemu/data/models/works/en_us.dart';
import 'package:lizunemu/data/models/works/i18n.dart';
import 'package:lizunemu/data/models/works/zh_cn.dart';
import 'package:lizunemu/presentation/models/search_command_suggestions.dart';

void main() {
  group('SearchCommandSuggestor tag suggestions', () {
    final catalog = {
      'Ear Cleaning': I18n(
        enUs: EnUs(name: 'Ear Cleaning'),
        zhCn: ZhCn(name: '掏耳'),
      ),
    };

    test('matches English display name and inserts official token', () {
      final suggestions = SearchCommandSuggestor.suggest(
        draft: r'$tag:ear',
        cursor: r'$tag:ear'.length,
        tagNames: const ['Ear Cleaning'],
        tagCatalog: catalog,
        appLanguage: AppLanguage.en,
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.first.title, 'Ear Cleaning');
      expect(suggestions.first.insertText, r'$tag:Ear Cleaning$');
      expect(suggestions.first.completeToken, isTrue);
    });

    test('matches Chinese alias when user types zh fragment', () {
      final suggestions = SearchCommandSuggestor.suggest(
        draft: r'$tag:掏',
        cursor: r'$tag:掏'.length,
        tagNames: const ['Ear Cleaning'],
        tagCatalog: catalog,
        appLanguage: AppLanguage.en,
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.first.title, 'Ear Cleaning');
    });
  });
}
