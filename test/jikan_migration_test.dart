import 'package:dailyanimelist/api/credmal.dart';
import 'package:dailyanimelist/api/jikan_models.dart';
import 'package:dailyanimelist/api/jikahelper.dart';
import 'package:dailyanimelist/api/maluser.dart';
import 'package:dailyanimelist/widgets/search/filtermodal.dart';
import 'package:dal_commons/commons.dart' show Constants;
import 'package:dal_commons/dal_commons.dart' show UserProfileV4;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Jikan base URL configuration', () {
    tearDown(() => CredMal.setJikanBaseUrlOverride(null));

    test('defaults to the jikan-edge replacement, not api.jikan.moe', () {
      expect(CredMal.jikanV4, 'https://jikan.lucashdo.com/v1/');
      expect(CredMal.jikanV4, isNot(contains('api.jikan.moe')));
    });

    test('settings override wins and keeps a trailing slash', () {
      CredMal.setJikanBaseUrlOverride('https://mirror.example.com/jikan');
      expect(CredMal.jikanV4, 'https://mirror.example.com/jikan/');
      // The bundled DAL handlers must follow the same base URL.
      expect(Constants.jikanV4, 'https://mirror.example.com/jikan/');
      expect(CredMal.jikanBaseUrlNotifier.value,
          'https://mirror.example.com/jikan/');
    });

    test('clearing the override restores the default', () {
      CredMal.setJikanBaseUrlOverride('https://mirror.example.com/');
      CredMal.setJikanBaseUrlOverride('   ');
      expect(CredMal.jikanV4, CredMal.defaultJikanBaseUrl);
    });
  });

  group('JikanAnimeStatistics', () {
    test('parses jikan-edge nested status (inProgress/planned)', () {
      final stats = JikanAnimeStatistics.fromJson({
        'status': {
          'inProgress': 10,
          'completed': 100,
          'onHold': 5,
          'dropped': 7,
          'planned': 20,
          'total': 142,
        },
        'scores': [
          {'score': 8, 'votes': 500, 'percentage': 33.3},
        ],
      });
      expect(stats.watching, 10);
      expect(stats.completed, 100);
      expect(stats.onHold, 5);
      expect(stats.planToWatch, 20);
      expect(stats.total, 142);
      expect(stats.scores!.single.votes, 500);
    });

    test('parses Jikan v4 flat status (watching/plan_to_watch/vote_count)',
        () {
      final stats = JikanAnimeStatistics.fromJson({
        'watching': 10,
        'completed': 100,
        'on_hold': 5,
        'dropped': 7,
        'plan_to_watch': 20,
        'total': 142,
        'scores': [
          {'score': 8, 'vote_count': 500, 'percentage': 33.3},
        ],
      });
      expect(stats.watching, 10);
      expect(stats.onHold, 5);
      expect(stats.planToWatch, 20);
      expect(stats.scores!.single.votes, 500);
    });
  });

  group('friend profile mapping (MalUser)', () {
    test('entry counts come from jikan-edge statistics', () {
      final v4 = UserProfileV4.fromJson({
        'profile': {
          'username': 'Xinil',
          'profileUrl': 'https://myanimelist.net/profile/Xinil',
          'avatarUrl': 'https://cdn.myanimelist.net/avatar.png',
          'gender': 'Male',
          'location': 'California',
          'birthday': 'Mar 4, 1985',
          'joinedAt': 'Nov 5, 2004',
        },
        'statistics': {
          'anime': {
            'watching': 1,
            'completed': 233,
            'onHold': 8,
            'dropped': 93,
            'planToWatch': 64,
            'totalEntries': 399,
            'rewatched': 60,
            'episodesWatched': 8481,
            'daysWatched': 142.3,
            'meanScore': 7.37,
          },
        },
      });
      final prof = MalUser.mapJikanUserToUserProf(v4);
      expect(prof.name, 'Xinil');
      expect(prof.gender, 'Male');
      expect(prof.location, 'California');
      expect(prof.picture, 'https://cdn.myanimelist.net/avatar.png');
      expect(prof.joinedAt, 'Nov 5, 2004');
      expect(prof.birthday, DateTime(1985, 3, 4));
      // jikan-edge has no numeric user id; the profile background lookup
      // must degrade to "no background" instead of throwing.
      expect(prof.id, isNull);
      final stats = prof.animeStatistics;
      expect(stats?.numItems, 399);
      expect(stats?.numItemsWatching, 1);
      expect(stats?.numItemsCompleted, 233);
      expect(stats?.numItemsOnHold, 8);
      expect(stats?.numItemsDropped, 93);
      expect(stats?.numItemsPlanToWatch, 64);
      expect(stats?.numEpisodes, 8481);
      expect(stats?.numDaysWatched, 142.3);
      expect(stats?.numTimesRewatched, 60);
      expect(stats?.meanScore, 7.37);
    });

    test('missing statistics stay null instead of zero-filled', () {
      final v4 = UserProfileV4.fromJson({'profile': {'username': 'NoStats'}});
      final prof = MalUser.mapJikanUserToUserProf(v4);
      expect(prof.name, 'NoStats');
      expect(prof.animeStatistics, isNull);
    });

    test('parseJikanDate accepts both date styles', () {
      expect(MalUser.parseJikanDate('1998-04-03'), DateTime(1998, 4, 3));
      expect(MalUser.parseJikanDate('1998-04-03T00:00:00+00:00')?.year, 1998);
      expect(MalUser.parseJikanDate('Mar 4, 1985'), DateTime(1985, 3, 4));
      expect(MalUser.parseJikanDate('Nov 5, 2004'), DateTime(2004, 11, 5));
      expect(MalUser.parseJikanDate('September 12, 2020'),
          DateTime(2020, 9, 12));
      expect(MalUser.parseJikanDate('Jul 3, 2:03 PM'), isNull);
      expect(MalUser.parseJikanDate(''), isNull);
      expect(MalUser.parseJikanDate(null), isNull);
    });
  });

  group('jikanSearch filter URL building', () {
    test('drops parameters the replacement API rejects outright', () {
      final url = JikanHelper.filterUrlBuilder({
        'sfw': FilterOption(value: 'true'),
        'producers': FilterOption(value: '1'),
        'magazines': FilterOption(value: '2'),
        'genres': FilterOption(
          type: FilterType.multiple,
          values: ['Action', 'Comedy'],
          apiValues: [1, 4],
          includedOptions: ['Action'],
          excludedOptions: ['Comedy'],
          excludeFieldName: 'genres_exclude',
        ),
      }, category: 'anime');
      expect(url, isNot(contains('sfw')));
      expect(url, isNot(contains('producers')));
      expect(url, isNot(contains('magazines')));
      expect(url, isNot(contains('genres_exclude')));
      // The supported part of the genre filter must survive.
      expect(url, contains('&genres=1'));
    });

    test('normalizes rating values (pg_13 -> pg13)', () {
      final url = JikanHelper.filterUrlBuilder({
        'rating': FilterOption(value: 'pg_13'),
      }, category: 'anime');
      expect(url, contains('&rating=pg13'));
      expect(url, isNot(contains('pg_13')));
    });

    test('keeps default ordering for content searches', () {
      final url = JikanHelper.filterUrlBuilder({
        'type': FilterOption(value: 'tv'),
      }, category: 'anime');
      expect(url, contains('&type=tv'));
      expect(url, contains('order_by=members'));
    });
  });
}
