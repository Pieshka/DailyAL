import 'dart:convert';

import 'package:dailyanimelist/cache/cachemanager.dart';
import 'package:dailyanimelist/cache/history_data.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/user/user.dart';
import 'package:dailyanimelist/util/streamutils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The search history and the recently viewed anime/manga live in one cached
/// blob. Backups used to skip it, so restoring a profile lost all of them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final historyKey = StreamUtils.i.key(StreamType.search_page);

  final historyBlob = {
    'queryHistory': ['one piece', 'frieren'],
    'recentAnime': [
      {'id': 21, 'title': 'One Piece'},
    ],
    'recentManga': [
      {'id': 121, 'title': 'One Piece (manga)'},
    ],
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    user = await User.getInstance();
    // CacheManager caches the SharedPreferences object; point it at the fresh
    // mock store of this test.
    CacheManager.pref = await SharedPreferences.getInstance();
    await CacheManager.instance.setCachedJson(historyKey, historyBlob);
  });

  test('the history key is stored under the search page stream key', () async {
    expect(historyKey, 'stream-utils-search_page-init-data');
    final cached =
        await CacheManager.instance.getCachedContent(historyKey) as Map;
    expect(cached['queryHistory'], ['one piece', 'frieren']);
  });

  test('a backup carries the search history by default', () async {
    final backup = jsonDecode(
      await CacheManager.instance.getBackUpData(),
    ) as Map<String, dynamic>;

    expect(backup.containsKey(historyKey), isTrue,
        reason: 'search history and viewed anime/manga must be part of the '
            'backup so a restored profile keeps them');
    final restoredHistory =
        jsonDecode(backup[historyKey]!) as Map<String, dynamic>;
    expect(restoredHistory['recentAnime'], hasLength(1));
    expect(restoredHistory['recentManga'], hasLength(1));
  });

  test('the history can be left out of a backup', () async {
    final backup = jsonDecode(
      await CacheManager.instance.getBackUpData(includeHistory: false),
    ) as Map<String, dynamic>;

    expect(backup.containsKey(historyKey), isFalse);
  });

  test('restoring a backup brings the history back', () async {
    final backup = await CacheManager.instance.getBackUpData();

    await CacheManager.instance.resetData();
    expect(await CacheManager.instance.getCachedContent(historyKey), isNull);

    expect(await CacheManager.instance.restoreData(backup), isTrue);
    await StreamUtils.i.init();
    final history = StreamUtils.i.initalData<HistoryData>(StreamType.search_page);

    expect(history.queryHistory, ['one piece', 'frieren']);
    expect(history.recentAnime.map((e) => e.id).toList(), [21]);
    expect(history.recentManga.map((e) => e.id).toList(), [121]);
  });
}
