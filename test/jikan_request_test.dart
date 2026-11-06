import 'dart:convert';
import 'dart:io';

import 'package:dailyanimelist/api/credmal.dart';
import 'package:dailyanimelist/api/jikahelper.dart';
import 'package:dailyanimelist/api/malconnect.dart';
import 'package:dailyanimelist/api/maluser.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/user/user.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// jikan-edge validates query parameters strictly: an unknown one answers
/// `400 UNKNOWN_PARAMETER`. MalConnect used to append the `nsfw`/`fromCache`
/// markers to every request, which made every Jikan call fail (friend
/// profiles, their entry counts, favorites, clubs and updates).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  final requestedUris = <String>[];

  setUp(() async {
    // flutter_test replaces the dart:io HTTP client with one that answers
    // every request with a fake 400; real sockets are needed here.
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    user = await User.getInstance();
    requestedUris.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      final path = request.uri.path;
      requestedUris.add(request.uri.toString());
      request.response.headers.contentType = ContentType.json;
      if (path.endsWith('/full')) {
        request.response.write(jsonEncode({
          'data': {
            'profile': {
              'username': 'shilgard',
              'avatarUrl': 'https://cdn.myanimelist.net/images/questionmark_23.gif',
              'joinedAt': 'Nov 5, 2004',
              'birthday': 'Mar 4, 1985',
            },
            'statistics': {
              'anime': {
                'watching': 12,
                'completed': 340,
                'onHold': 3,
                'dropped': 21,
                'planToWatch': 60,
                'totalEntries': 436,
                'rewatched': 4,
                'episodesWatched': 9000,
                'daysWatched': 120.5,
                'meanScore': 7.4,
              },
            },
          },
        }));
      } else {
        request.response.write(jsonEncode({'ok': true}));
      }
      request.response.close();
    });
    CredMal.setJikanBaseUrlOverride('http://127.0.0.1:${server.port}/v1/');
  });

  tearDown(() async {
    CredMal.setJikanBaseUrlOverride(null);
    HttpOverrides.global = null;
    await server.close(force: true);
  });

  group('Jikan request parameters', () {
    test('no nsfw/fromCache markers are appended to Jikan routes', () async {
      final result = await JikanHelper.getUserInfo(
        username: 'shilgard',
        fromCache: false,
      );
      expect(requestedUris, hasLength(1));
      final uri = Uri.parse(requestedUris.single);
      expect(uri.path, '/v1/users/shilgard/full');
      expect(uri.queryParameters.containsKey('nsfw'), isFalse,
          reason: 'jikan-edge rejects nsfw with 400 UNKNOWN_PARAMETER');
      expect(uri.queryParameters.containsKey('fromCache'), isFalse);
      expect(result.data?.username, 'shilgard');
    });

    test('the MAL/DAL markers are still appended to other endpoints', () async {
      // A different origin: the Jikan check compares authorities, so reusing
      // the Jikan server's port would prove nothing.
      final plainServer =
          await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      plainServer.listen((request) {
        requestedUris.add(request.uri.toString());
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'ok': true}))
          ..close();
      });
      await MalConnect.getContent(
        'http://127.0.0.1:${plainServer.port}/anime/1',
        withNoHeaders: true,
        fromCache: false,
      );
      await plainServer.close(force: true);
      expect(requestedUris, hasLength(1));
      final params = Uri.parse(requestedUris.single).queryParameters;
      expect(params.containsKey('nsfw'), isTrue);
      expect(params['fromCache'], 'false');
    });

    test('friend profile statistics reach the entry counters', () async {
      final prof = await MalUser.getUserInfo(
        username: 'shilgard',
        fromCache: false,
      );
      final stats = prof?.animeStatistics;
      expect(stats, isNotNull,
          reason: 'a 400 from Jikan left every friend profile without stats');
      expect(stats?.numItemsWatching, 12);
      expect(stats?.numItemsCompleted, 340);
      expect(stats?.numItemsOnHold, 3);
      expect(stats?.numItemsDropped, 21);
      expect(stats?.numItemsPlanToWatch, 60);
      expect(stats?.numItems, 436);
    });
  });
}
