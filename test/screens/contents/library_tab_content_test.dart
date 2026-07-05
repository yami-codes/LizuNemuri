import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/database/database_bootstrap.dart';
import 'package:lizunemu/core/di/service_locator.dart';
import 'package:lizunemu/presentation/viewmodels/home_viewmodel.dart';
import 'package:lizunemu/screens/contents/library_tab_content.dart';

/// Regression: LibraryTabContent must read LocalLibraryViewModel from a
/// descendant context (inside MultiProvider), not the outer build context.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await bootstrapDatabaseFactory();
    await setupServiceLocator();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('renders local segment shell without ProviderNotFound',
      (tester) async {
    final homeVm = HomeViewModel();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider.value(
          value: homeVm,
          child: const LibraryTabContent(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(Strings.librarySegmentLocal), findsWidgets);
    expect(find.text(Strings.localLibraryAddFolder), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    // HomeContent (IndexedStack sibling) starts a paginated fetch; flush timers.
    await tester.pump(const Duration(seconds: 65));
  });
}
