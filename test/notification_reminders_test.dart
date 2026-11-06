import 'dart:convert';

import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/notifservice.dart';
import 'package:dailyanimelist/pages/settings/notifsettings.dart';
import 'package:dailyanimelist/user/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The settings page can now list every queued episode reminder and rebuild
/// them. Reminders queued by an older app run carry a payload without a
/// poster, which is why those notifications showed no cover art.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    user = await User.getInstance();
  });

  group('ScheduledReminder manifest entries', () {
    test('survive a round trip', () {
      final reminder = ScheduledReminder(
        notificationId: 4321,
        malId: 2121,
        title: 'Ep: 5 of One Piece is out!',
        body: 'Update your watch list',
        scheduledFor: DateTime.fromMillisecondsSinceEpoch(1800000000000),
        hasArtwork: true,
        posterUrl: 'https://cdn.myanimelist.net/images/anime/6/73245l.jpg',
      );

      final restored =
          ScheduledReminder.fromManifestJson(4321, reminder.toManifestJson());

      expect(restored.notificationId, 4321);
      expect(restored.malId, 2121);
      expect(restored.title, reminder.title);
      expect(restored.body, reminder.body);
      expect(restored.scheduledFor, reminder.scheduledFor);
      expect(restored.hasArtwork, isTrue);
      expect(restored.posterUrl, reminder.posterUrl,
          reason: 'the preview shows the queued entry artwork');
    });

    test('a missing time or artwork flag degrades to null/false', () {
      final restored = ScheduledReminder.fromManifestJson(1, {
        'malId': 'not-a-number',
        'title': null,
      });
      expect(restored.scheduledFor, isNull);
      expect(restored.hasArtwork, isFalse);
      expect(restored.posterUrl, isNull);
      expect(restored.malId, 0);
      expect(restored.title, '');
    });
  });

  group('Queued reminder preview', () {
    test('is empty and prunes manifest entries that are no longer queued',
        () async {
      SharedPreferences.setMockInitialValues({
        NotificationService.reminderManifestKey: jsonEncode({
          '4321': {
            'malId': 2121,
            'title': 'already fired',
            'time': 1800000000000,
            'artwork': true,
          },
        }),
      });

      final reminders = await NotificationService().pendingReminders();
      expect(reminders, isEmpty,
          reason: 'nothing is queued, so the preview must not invent entries');

      final prefs = await SharedPreferences.getInstance();
      final manifest =
          jsonDecode(prefs.getString(NotificationService.reminderManifestKey) ??
              '{}');
      expect(manifest, isEmpty, reason: 'fired reminders must be pruned');
    });

    test('the reset button cannot throw when nothing can be scheduled',
        () async {
      // No signed-in account and no notification backend in the test
      // environment: the reset must degrade to "0 reminders queued".
      final count = await NotificationService().resetScheduledReminders();
      expect(count, 0);
    });
  });

  testWidgets('the settings page offers the reset action and a preview',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: const NotificationSettingsPage(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Queued Notifications'), findsOneWidget);
    expect(find.text('Reset Scheduled Notifications'), findsOneWidget);
    expect(find.text('No notifications are currently scheduled'),
        findsOneWidget);
  });
}
