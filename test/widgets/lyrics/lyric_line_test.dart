import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/theme/app_colors.dart';
import 'package:lizunemu/widgets/lyrics/components/lyric_line.dart';
import 'package:lizunemu/widgets/player/player_immersive_scope.dart';

Widget _host({
  required Widget child,
  ColorScheme? scheme,
  PlayerImmersiveColors? immersive,
}) {
  final colorScheme = scheme ?? AppColors.lightSchemeFor(ColorVariant.blue);
  Widget body = Scaffold(body: Center(child: child));
  if (immersive != null) {
    body = PlayerImmersiveScope(colors: immersive, child: body);
  }
  return MaterialApp(
    theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
    home: body,
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

    testWidgets('renders dual subtitle stack', (tester) async {
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

    testWidgets('high emphasis uses bolder primary style', (tester) async {
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
      expect(high.style?.fontSize, 20);
    });

    testWidgets('low emphasis uses lighter primary style', (tester) async {
      await tester.pumpWidget(
        _host(
          child: const LyricLine(
            subtitle: _line,
            emphasis: 0.0,
          ),
        ),
      );
      final low = tester.widget<Text>(find.text('translated line'));
      expect(low.style?.fontWeight, FontWeight.w400);
      expect(low.style?.fontSize, 18);
    });

    testWidgets('immersive scope tints active lyric color', (tester) async {
      const immersive = PlayerImmersiveColors(
        activeLyric: Color(0xFFFFEEAA),
        inactiveLyric: Color(0xFF888888),
        accentStrong: Color(0xFFFFCC00),
        backdropTint: Color(0xFF222222),
        enabled: true,
      );
      await tester.pumpWidget(
        _host(
          immersive: immersive,
          child: const LyricLine(
            subtitle: _line,
            emphasis: 1.0,
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('translated line'));
      expect(text.style?.color, immersive.activeLyric);
    });
  });
}
