import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/subtitle/managers/subtitle_state_manager.dart';

SubtitleList _listWithText(String text) {
  return SubtitleList([
    Subtitle(
      start: const Duration(seconds: 0),
      end: const Duration(seconds: 5),
      text: text,
      index: 0,
    ),
    const Subtitle(
      start: Duration(seconds: 5),
      end: Duration(seconds: 10),
      text: 'line two',
      index: 1,
    ),
  ]);
}

void main() {
  group('SubtitleStateManager streaming replace', () {
    late SubtitleStateManager manager;

    setUp(() {
      manager = SubtitleStateManager();
    });

    test('replacing list keeps current cue by index without null flash', () async {
      final events = <SubtitleWithState?>[];
      final sub = manager.currentSubtitleWithStateStream.listen(events.add);

      final original = _listWithText('hello');
      manager.setSubtitleList(original);
      manager.updatePosition(const Duration(seconds: 2));

      expect(manager.currentSubtitle?.index, 0);
      expect(manager.currentSubtitle?.text, 'hello');
      expect(events.where((e) => e == null), isEmpty);

      events.clear();
      manager.setSubtitleList(_listWithText('hello translated'));

      expect(manager.currentSubtitle?.index, 0);
      expect(manager.currentSubtitle?.text, 'hello translated');
      expect(events.where((e) => e == null), isEmpty);
      expect(events, isEmpty);

      await sub.cancel();
    });

    test('updatePosition moves active cue to next index', () {
      manager.setSubtitleList(_listWithText('hello'));
      manager.updatePosition(const Duration(seconds: 2));
      expect(manager.currentSubtitle?.index, 0);

      manager.updatePosition(const Duration(seconds: 6));
      expect(manager.currentSubtitle?.index, 1);
      expect(manager.currentSubtitle?.text, 'line two');
    });

    test('same-index text refresh from position does not re-emit stream', () async {
      final events = <SubtitleWithState?>[];
      final sub = manager.currentSubtitleWithStateStream.listen(events.add);

      manager.setSubtitleList(_listWithText('hello'));
      manager.updatePosition(const Duration(seconds: 2));
      events.clear();

      manager.setSubtitleList(_listWithText('hello v2'));
      manager.updatePosition(const Duration(seconds: 2));

      expect(manager.currentSubtitle?.text, 'hello v2');
      expect(events, isEmpty);

      await sub.cancel();
    });
  });
}
