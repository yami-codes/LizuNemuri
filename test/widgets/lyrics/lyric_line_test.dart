import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/theme/app_colors.dart';
import 'package:lizunemu/widgets/lyrics/components/lyric_line.dart';

Widget _host({
  required Widget child,
  ColorScheme? scheme,
}) {
  final colorScheme = scheme ?? AppColors.lightSchemeFor(ColorVariant.blue);
  return MaterialApp(
    theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
    home: Scaffold(body: Center(child: child)),
  );
}

const _line = Subtitle(
  start: Duration.zero,
  end: Duration(seconds: 2),
  text: 'translated line',
  index: 0,
);

void main() {
  group('LyricLine', () {
    testWidgets('renders single primary line', (tester) async {
      await tester.pumpWidget(
        _host(child: const LyricLine(subtitle: _line, emphasis: 1.0)),
      );
      expect(find.text('translated line'), findsOneWidget);
    });

    testWidgets('renders dual subtitle stack when secondary provided', (tester) async {
      await tester.pumpWidget(
        _host(
          child: const LyricLine(
            subtitle: _line,
            secondaryText: 'original line',
            emphasis: 1.0,
          ),
        ),
      );
      expect(find.text('original line'), findsOneWidget);
      expect(find.text('translated line'), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('high emphasis uses bolder active style', (tester) async {
      await tester.pumpWidget(
        _host(
          child: const LyricLine(
            subtitle: _line,
            emphasis: 1.0,
          ),
        ),
      );
      final high = tester.widget<Text>(find.text('translated line'));
      expect(high.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('low emphasis uses lighter inactive style', (tester) async {
      await tester.pumpWidget(
        _host(
          child: const LyricLine(
            subtitle: _line,
            emphasis: 0.2,
          ),
        ),
      );
      final low = tester.widget<Text>(find.text('translated line'));
      expect(low.style?.fontWeight, FontWeight.w400);
    });

    testWidgets('active line gets primaryContainer pill', (tester) async {
      await tester.pumpWidget(
        _host(
          child: const LyricLine(
            subtitle: _line,
            emphasis: 1.0,
          ),
        ),
      );
      expect(find.byType(DecoratedBox), findsOneWidget);
    });
  });
}
