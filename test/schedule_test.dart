import 'package:dailyanimelist/api/dalapi.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/user/user.dart';
import 'package:dal_commons/commons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ScheduleData entry(String? malLink, {int? timestamp = 1764000000, int? episode}) {
  return ScheduleData.fromJson({
    'timestamp': timestamp,
    'episode': episode,
    if (malLink != null) 'relatedLinks': {'mal': malLink},
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // flutter_secure_storage has no implementation in the test environment;
    // stub it so User.getInstance() can read an empty auth response.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    user = await User.getInstance();
  });

  group('DalApi.scheduleMalId', () {
    test('extracts the MAL id from a valid related link', () {
      expect(
        DalApi.scheduleMalId(entry('https://myanimelist.net/anime/21/Naruto')),
        21,
      );
    });

    test('returns null (not a crash) when the MAL link is missing', () {
      // Regression: Uri.parse(null) used to throw, permanently poisoning the
      // shared schedule future so no countdown ever rendered.
      expect(DalApi.scheduleMalId(entry(null)), isNull);
      expect(DalApi.scheduleMalId(entry('')), isNull);
      expect(DalApi.scheduleMalId(entry('not a url')), isNull);
    });
  });

  group('DalApi.parseScheduleResponse', () {
    test('builds a malId -> schedule map from a well-formed response', () {
      final map = DalApi.parseScheduleResponse({
        'data': [
          {
            'timestamp': 1700000000,
            'episode': 5,
            'relatedLinks': {'mal': 'https://myanimelist.net/anime/21/Naruto'},
          },
          {
            'timestamp': 1700000600,
            'episode': 12,
            'relatedLinks': {
              'mal': 'https://myanimelist.net/anime/5114/Fullmetal_Alchemist'
            },
          },
        ],
      });
      expect(map.keys, containsAll(<int>[21, 5114]));
      expect(map[21]?.episode, 5);
      expect(map[5114]?.timestamp, 1700000600);
    });

    test('skips entries with missing or malformed MAL links without throwing',
        () {
      final map = DalApi.parseScheduleResponse({
        'data': [
          {'timestamp': 1700000000, 'episode': 1},
          {
            'timestamp': 1700000100,
            'episode': 2,
            'relatedLinks': {'mal': ''}
          },
          {
            'timestamp': 1700000200,
            'episode': 3,
            'relatedLinks': {'website': 'https://example.com'}
          },
          {
            'timestamp': 1700000300,
            'episode': 4,
            'relatedLinks': {'mal': 'https://myanimelist.net/anime/11757'}
          },
        ],
      });
      expect(map.keys, <int>[11757]);
    });

    test('an empty data list parses to an empty map', () {
      expect(DalApi.parseScheduleResponse({'data': <Object>[]}), isEmpty);
    });
  });

  group('DalApi schedule failure fallback', () {
    test('a failed schedule refresh keeps the last known data', () async {
      // In the test environment the DAL endpoint is unreachable and resolves
      // to the local handler, which yields no usable data. The old code left
      // an empty map cached forever; the fix must retain the previous map.
      final known = {21: entry('https://myanimelist.net/anime/21/Naruto')};
      DalApi.i.scheduleForMalIdsSync = known;
      DalApi.i.resetScheduleForMalIds();
      final result = await DalApi.i.scheduleForMalIds;
      expect(result.containsKey(21), isTrue,
          reason: 'last-known-good schedule data must survive a failed fetch');
      expect(result[21]?.timestamp, isNotNull);
    });

    test('scheduleForMalIds returns the same future instance when cached', () {
      final a = DalApi.i.scheduleForMalIds;
      final b = DalApi.i.scheduleForMalIds;
      expect(identical(a, b), isTrue,
          reason: 'FutureBuilder widgets must not be re-pointed at a new '
              'future on every rebuild');
    });
  });
}
