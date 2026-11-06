import 'package:dailyanimelist/api/api_endpoint_settings.dart';
import 'package:dailyanimelist/api/credmal.dart';
import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/pages/settings/api_endpoints_settings.dart';
import 'package:dailyanimelist/user/user.dart';
import 'package:dal_commons/commons.dart' show Constants;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // flutter_secure_storage has no implementation in the test environment;
    // stub it so User.getInstance() can read an empty auth response. The
    // settings header reads the global `user`, so it must be initialized.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    user = await User.getInstance();
    CredMal.setJikanBaseUrlOverride(null);
    CredMal.setApiURLOverride(null);
    CredMal.setAppConfigUrlOverride(null);
  });

  tearDown(() {
    CredMal.setJikanBaseUrlOverride(null);
    CredMal.setApiURLOverride(null);
    CredMal.setAppConfigUrlOverride(null);
  });

  group('ApiEndpointSettings validation', () {
    test('rejects malformed URLs and keeps the previous value', () async {
      for (final bad in ['not a url', 'ftp://example.com', 'example.com']) {
        final error = await ApiEndpointSettings.saveOverride(
            ApiEndpointSettings.keyJikanBaseUrl, bad);
        expect(error, isNotNull, reason: '"$bad" must be rejected');
      }
      expect(CredMal.jikanV4, CredMal.defaultJikanBaseUrl);
      final stored = await ApiEndpointSettings.stored();
      expect(stored[ApiEndpointSettings.keyJikanBaseUrl], isNull);
    });

    test('accepts http/https URLs and applies them immediately', () async {
      final error = await ApiEndpointSettings.saveOverride(
          ApiEndpointSettings.keyJikanBaseUrl, 'https://mirror.example.com/v1');
      expect(error, isNull);
      expect(CredMal.jikanV4, 'https://mirror.example.com/v1/');
      // The bundled DAL handlers follow the same base URL.
      expect(Constants.jikanV4, 'https://mirror.example.com/v1/');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ApiEndpointSettings.keyJikanBaseUrl),
          'https://mirror.example.com/v1');
    });

    test('saving an empty value clears the override', () async {
      await ApiEndpointSettings.saveOverride(
          ApiEndpointSettings.keyDalApiUrl, 'https://custom.example.com');
      expect(CredMal.apiURL, 'https://custom.example.com');
      await ApiEndpointSettings.saveOverride(
          ApiEndpointSettings.keyDalApiUrl, '   ');
      expect(CredMal.apiURLOverride, isNull);
      expect(CredMal.apiURL, CredMal.defaultApiURL);
    });
  });

  group('ApiEndpointSettings persistence', () {
    test('loadAndApply restores overrides after a restart', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          ApiEndpointSettings.keyJikanBaseUrl, 'https://jikan.example.org/v1/');
      await prefs.setString(
          ApiEndpointSettings.keyDalConfigUrl, 'https://config.example.org');

      CredMal.setJikanBaseUrlOverride(null);
      CredMal.setAppConfigUrlOverride(null);
      await ApiEndpointSettings.loadAndApply();

      expect(CredMal.jikanV4, 'https://jikan.example.org/v1/');
      expect(CredMal.appConfigUrl, 'https://config.example.org');
    });

    test('resetAll removes every stored override', () async {
      await ApiEndpointSettings.saveOverride(
          ApiEndpointSettings.keyJikanBaseUrl, 'https://a.example.com/v1');
      await ApiEndpointSettings.saveOverride(
          ApiEndpointSettings.keyDalApiUrl, 'https://b.example.com');
      await ApiEndpointSettings.saveOverride(
          ApiEndpointSettings.keyDalConfigUrl, 'https://c.example.com');

      await ApiEndpointSettings.resetAll();

      final stored = await ApiEndpointSettings.stored();
      expect(stored.values.every((v) => v == null), isTrue);
      expect(CredMal.jikanV4, CredMal.defaultJikanBaseUrl);
      expect(CredMal.apiURL, CredMal.defaultApiURL);
      expect(CredMal.appConfigUrl, CredMal.defaultAppConfigUrl);
    });
  });

  testWidgets('settings page shows stored values and saves edits',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      ApiEndpointSettings.keyJikanBaseUrl: 'https://saved.example.com/v1',
    });
    // The form is taller than the default 800x600 test surface; give it room
    // so the Save button is actually hittable.
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: const ApiEndpointsSettingsPage(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('API Endpoints'), findsOneWidget);
    expect(find.text('https://saved.example.com/v1'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(ApiEndpointSettings.keyJikanBaseUrl), isFalse);
    expect(CredMal.jikanV4, CredMal.defaultJikanBaseUrl);
  });
}
