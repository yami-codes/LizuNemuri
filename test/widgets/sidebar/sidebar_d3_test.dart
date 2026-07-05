import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xuro/core/settings/app_settings_service.dart';
import 'package:xuro/core/theme/app_colors.dart';
import 'package:xuro/widgets/sidebar/sidebar_decoration.dart';

Widget _host(ColorScheme s, Widget child) => MaterialApp(
      theme: ThemeData(colorScheme: s, useMaterial3: true),
      home: Scaffold(body: child),
    );

void main() {
  group('SidebarDecoration Monet motif', () {
    testWidgets('light → leaves', (tester) async {
      final scheme = AppColors.lightSchemeFor(ColorVariant.blue);
      await tester.pumpWidget(_host(scheme, const SidebarDecoration()));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark → moon', (tester) async {
      final scheme = AppColors.darkSchemeFor(ColorVariant.blue);
      await tester.pumpWidget(_host(scheme, const SidebarDecoration()));
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
