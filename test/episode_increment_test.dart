import 'dart:async';
import 'dart:convert';

import 'package:dailyanimelist/api/auth/authresp.dart';
import 'package:dailyanimelist/api/malconnect.dart';
import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/user/user.dart';
import 'package:dailyanimelist/widgets/user/contentlistwidget.dart';
import 'package:dal_commons/dal_commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tapping the + button used to leave the watched count unchanged until the
/// MAL write and the cached list rewrite had both finished. The row now
/// updates immediately, and taps that arrive while a write is in flight are
/// merged into one follow-up request with the latest count.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> bodies;
  late List<Completer<http.Response>> pending;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    user = await User.getInstance();
    user.status = AuthStatus.AUTHENTICATED;
    user.authResponse = AuthResponse(
      accessToken: 'access-token',
      tokenType: 'Bearer',
      expiresIn: 3600,
      refreshToken: 'refresh-token',
      createdTime: DateTime.now(),
    );
    bodies = <String>[];
    pending = <Completer<http.Response>>[];
    MalConnect.testHttpClient = MockClient((request) {
      // Startup config lookups also go through this client; they are not part
      // of what this test measures.
      if (request.method != 'PUT') {
        return Future.value(http.Response('{}', 200));
      }
      bodies.add(request.body);
      final completer = Completer<http.Response>();
      pending.add(completer);
      return completer.future;
    });
  });

  tearDown(() {
    MalConnect.testHttpClient = null;
  });

  /// The episode counts that were actually sent, in order.
  List<int> writtenCounts() => bodies
      .map((body) => Uri.splitQueryString(body)['num_watched_episodes'])
      .map((value) => int.parse(value!))
      .toList();

  http.Response listStatusResponse(int watched) => http.Response(
        jsonEncode({
          'status': 'watching',
          'score': 0,
          'num_episodes_watched': watched,
          'is_rewatching': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }),
        200,
        headers: {'content-type': 'application/json'},
      );

  Future<void> pumpList(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    final node = BaseNode(
      content: AnimeDetailed(id: 4242, title: 'Test Anime', numEpisodes: 12),
      myListStatus:
          MyAnimeListStatus(numEpisodesWatched: 1, status: 'watching'),
    );
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: ContentListWidget(
          contentList: [node],
          showImage: false,
          returnSlivers: false,
        ),
      ),
    ));
    await tester.pump();
  }

  /// The row shows a loading spinner while a write is in flight, so
  /// [WidgetTester.pumpAndSettle] would never settle (and would advance fake
  /// time far enough to trip the write timeout). Pump a few frames instead.
  Future<void> pumpTicks(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  testWidgets('the watched count updates before MAL answers', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpList(tester);

    expect(find.text('1 Eps'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(pending, hasLength(1));
    expect(pending.single.isCompleted, isFalse);
    expect(find.text('2 Eps'), findsOneWidget,
        reason: 'the row must show the new count without waiting for MAL');

    pending.single.complete(listStatusResponse(2));
    await pumpTicks(tester);

    expect(find.text('2 Eps'), findsOneWidget);
    expect(writtenCounts(), [2]);
  });

  testWidgets('rapid taps merge into a single follow-up write', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpList(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
    }

    expect(find.text('4 Eps'), findsOneWidget,
        reason: 'every tap updates the count right away');
    expect(pending, hasLength(1),
        reason: 'the taps share the write that is already in flight');
    expect(writtenCounts(), [2]);

    pending.first.complete(listStatusResponse(2));
    await pumpTicks(tester);

    expect(pending, hasLength(2),
        reason: 'the latest target is written once the first write lands');
    expect(writtenCounts(), [2, 4]);
    expect(find.text('4 Eps'), findsOneWidget);

    pending.last.complete(listStatusResponse(4));
    await pumpTicks(tester);

    expect(find.text('4 Eps'), findsOneWidget);
    expect(writtenCounts(), [2, 4]);
  });

  testWidgets('a failed write restores the last confirmed count',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpList(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2 Eps'), findsOneWidget);

    pending.single.complete(http.Response('rejected', 400));
    await pumpTicks(tester);

    expect(find.text('1 Eps'), findsOneWidget,
        reason: 'the optimistic count must not stick when MAL rejects it');
  });
}
