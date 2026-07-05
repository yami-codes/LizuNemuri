import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/di/service_locator.dart';
import 'package:lizunemu/core/settings/app_language.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await setupServiceLocator();
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('Strings resolves English when app language is en', () async {
    await getIt<AppSettingsService>().setAppLanguage(AppLanguage.en);
    expect(Strings.settings, 'Settings');
    expect(Strings.retry, 'Retry');
  });

  test('Strings resolves Thai when app language is th', () async {
    await getIt<AppSettingsService>().setAppLanguage(AppLanguage.th);
    expect(Strings.settings, 'การตั้งค่า');
  });

  test('Strings resolves Chinese when app language is zh', () async {
    await getIt<AppSettingsService>().setAppLanguage(AppLanguage.zh);
    expect(Strings.settings, '设置');
  });
}
