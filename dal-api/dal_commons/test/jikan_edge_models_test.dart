import 'package:dal_commons/src/model/dal/animevideo.dart';
import 'package:dal_commons/src/model/dal/characterv4.dart';
import 'package:dal_commons/src/model/dal/clubV4.dart';
import 'package:dal_commons/src/model/dal/clubinfov4.dart';
import 'package:dal_commons/src/model/dal/commonV4.dart';
import 'package:dal_commons/src/model/dal/peoplev4.dart';
import 'package:dal_commons/src/model/dal/userfavV4.dart';
import 'package:dal_commons/src/model/dal/userprofv4.dart';
import 'package:dal_commons/src/model/dal/userupdateV4.dart';
import 'package:dal_commons/src/model/jikan/jikan_anime.dart';
import 'package:test/test.dart';

/// Fixtures mirror real responses captured from jikan-edge
/// (https://jikan.lucashdo.com/v1) and Jikan v4 (snake_case), because the
/// models must keep parsing both formats.
void main() {
  group('UserProfileV4 (friend profile counts/background)', () {
    test('parses jikan-edge nested profile + camelCase statistics', () {
      final user = UserProfileV4.fromJson({
        'profile': {
          'username': 'Xinil',
          'profileUrl': 'https://myanimelist.net/profile/Xinil',
          'avatarUrl': 'https://cdn.myanimelist.net/avatar.png',
          'gender': 'Male',
          'location': 'California',
          'joinedAt': 'Nov 5, 2004',
          'lastOnlineAt': 'Jul 3, 2:03 PM',
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
          'manga': {
            'reading': 15,
            'completed': 12,
            'totalEntries': 76,
            'chaptersRead': 3283,
            'daysRead': 17.6,
            'meanScore': 7.35,
          },
        },
      });
      expect(user.username, 'Xinil');
      expect(user.url, 'https://myanimelist.net/profile/Xinil');
      expect(user.joined, 'Nov 5, 2004');
      expect(user.images?.jpg?.imageUrl, 'https://cdn.myanimelist.net/avatar.png');
      final anime = user.statistics?.anime;
      expect(anime?.totalEntries, 399);
      expect(anime?.completed, 233);
      expect(anime?.onHold, 8);
      expect(anime?.planToWatch, 64);
      expect(anime?.episodesWatched, 8481);
      expect(anime?.daysWatched, 142.3);
      expect(anime?.meanScore, 7.37);
      expect(user.statistics?.manga?.chaptersRead, 3283);
    });

    test('still parses Jikan v4 flat snake_case profile', () {
      final user = UserProfileV4.fromJson({
        'mal_id': 1,
        'username': 'OldFormat',
        'url': 'https://myanimelist.net/profile/OldFormat',
        'images': {
          'jpg': {'image_url': 'https://cdn/old.jpg'},
        },
        'joined': '2004-11-05T00:00:00+00:00',
        'statistics': {
          'anime': {
            'days_watched': 142.3,
            'mean_score': 7.37,
            'watching': 1,
            'completed': 233,
            'on_hold': 8,
            'dropped': 93,
            'plan_to_watch': 64,
            'total_entries': 399,
            'rewatched': 60,
            'episodes_watched': 8481,
          },
        },
      });
      expect(user.malId, 1);
      expect(user.username, 'OldFormat');
      expect(user.images?.jpg?.imageUrl, 'https://cdn/old.jpg');
      expect(user.statistics?.anime?.totalEntries, 399);
      expect(user.statistics?.anime?.daysWatched, 142.3);
      expect(user.statistics?.anime?.planToWatch, 64);
    });
  });

  group('favorites / clubs / updates / videos', () {
    test('jikan-edge favorites', () {
      final fav = UserFavV4.fromJson({
        'anime': [
          {
            'malId': 1,
            'title': 'Cowboy Bebop',
            'url': 'https://myanimelist.net/anime/1',
            'type': 'TV',
            'startYear': 1998,
            'imageUrl': 'https://cdn/bebop.jpg',
          },
        ],
        'characters': [
          {'malId': 1, 'name': 'Spiegel', 'imageUrl': 'https://cdn/spike.jpg'},
        ],
        'people': [
          {'malId': 1, 'name': 'Seki', 'imageUrl': 'https://cdn/seki.jpg'},
        ],
      });
      expect(fav.anime!.single.malId, 1);
      expect(fav.anime!.single.startYear, 1998);
      expect(fav.anime!.single.images?.jpg?.imageUrl, 'https://cdn/bebop.jpg');
      expect(fav.characters!.single.name, 'Spiegel');
      expect(fav.people!.single.images?.jpg?.imageUrl, 'https://cdn/seki.jpg');
    });

    test('jikan-edge user clubs', () {
      final clubs = ClubV4List.fromList([
        {
          'malId': 263,
          'name': "1, 2, 3 Let's Switch!",
          'url': 'https://myanimelist.net/clubs.php?cid=263',
        },
      ]);
      expect(clubs.data!.single.malId, 263);
      expect(clubs.data!.single.name, "1, 2, 3 Let's Switch!");
    });

    test('jikan-edge club info renames (title/members/created)', () {
      final club = Club.fromJson({
        'malId': 100,
        'url': 'https://myanimelist.net/clubs.php?cid=100',
        'title': 'Club Name',
        'members': 42,
        'pictures': 3,
        'category': 'Public',
        'created': '2008-01-01',
      });
      expect(club.malId, 100);
      expect(club.name, 'Club Name');
      expect(club.members, 42);
      expect(club.created, '2008-01-01');
    });

    test('jikan-edge user updates (progress/total)', () {
      final list = UserUpdateList.fromJson([
        {
          'username': 'SomeUser',
          'imageUrl': 'https://cdn/user.png',
          'score': 8,
          'status': 'watching',
          'progress': 12,
          'total': 24,
          'date': '2026-11-01',
        },
      ]);
      final update = list.data!.single;
      expect(update.user?.username, 'SomeUser');
      expect(update.user?.images?.jpg?.imageUrl, 'https://cdn/user.png');
      expect(update.score, 8.0);
      expect(update.episodesSeen, 12);
      expect(update.episodesTotal, 24);
      expect(update.date, '2026-11-01');
    });

    test('jikan-edge videos (promos/musicVideos flattening)', () {
      final videos = AnimeVideoV4.fromJson({
        'promos': [
          {
            'title': 'PV1',
            'videoUrl': 'https://www.youtube.com/watch?v=abc123def45',
            'imageUrl': 'https://cdn/pv1.jpg',
          },
        ],
        'musicVideos': [],
        'episodes': [
          {
            'episode': 3,
            'title': 'Episode 3',
            'url': 'https://myanimelist.net/video/1',
            'imageUrl': 'https://cdn/ep3.jpg',
          },
        ],
      });
      final promo = videos.promo!.single;
      expect(promo.title, 'PV1');
      expect(promo.trailer?.youtubeId, 'abc123def45');
      expect(promo.trailer?.images?.imageUrl, 'https://cdn/pv1.jpg');
      final ep = videos.episodes!.single;
      expect(ep.episode, '3');
      expect(ep.images?.jpg?.imageUrl, 'https://cdn/ep3.jpg');
    });
  });

  group('characters / people', () {
    test('jikan-edge character full (camelCase + flat works/voices)', () {
      final char = CharacterV4Data.fromJson({
        'malId': 1,
        'url': 'https://myanimelist.net/character/1/Spike_Spiegel',
        'name': 'Spike Spiegel',
        'nicknames': [],
        'nameKanji': 'スパイク・スピーゲル',
        'imageUrl': 'https://cdn/spike.jpg',
        'images': {'small': null, 'medium': 'https://cdn/spike.jpg', 'large': null},
        'about': 'Birthdate: June 26, 2044',
        'favorites': 12345,
        'anime': [
          {'malId': 1, 'title': 'Cowboy Bebop', 'imageUrl': 'https://cdn/bebop.jpg', 'role': 'Main'},
        ],
        'voices': [
          {'malId': 11, 'name': 'Yamadera, Kouichi', 'imageUrl': 'https://cdn/voice.jpg', 'language': 'Japanese'},
        ],
      });
      expect(char.malId, 1);
      expect(char.nameKanji, 'スパイク・スピーゲル');
      // images map has only medium set -> synthesized jpg
      expect(char.images?.jpg?.imageUrl, 'https://cdn/spike.jpg');
      final role = char.anime!.single;
      expect(role.role, 'Main');
      expect(role.anime?.malId, 1);
      expect(role.anime?.images?.jpg?.imageUrl, 'https://cdn/bebop.jpg');
      final voice = char.voices!.single;
      expect(voice.language, 'Japanese');
      expect(voice.person?.malId, 11);
      expect(voice.person?.name, 'Yamadera, Kouichi');
    });

    test('jikan-edge people full', () {
      final person = PeopleV4Data.fromJson({
        'malId': 1,
        'name': 'Seki, Tomokazu',
        'givenName': '智一',
        'familyName': '関',
        'alternateNames': ['Seki Mondoya'],
        'birthday': 'Sep 8, 1972',
        'website': null,
        'imageUrl': 'https://cdn/seki.jpg',
      });
      expect(person.givenName, '智一');
      expect(person.familyName, '関');
      expect(person.alternateNames, ['Seki Mondoya']);
      expect(person.images?.jpg?.imageUrl, 'https://cdn/seki.jpg');
    });
  });

  group('JikanAnime (search items)', () {
    test('jikan-edge flat search item parses without crashing', () {
      final anime = JikanAnime.fromJson({
        'malId': 20,
        'url': 'https://myanimelist.net/anime/20/Naruto',
        'title': 'Naruto',
        'imageUrl': 'https://cdn/naruto.jpg',
        'synopsis': 'Twelve years ago...',
        'type': 'TV',
        'score': 8.03,
        'startDate': '2002-10-03',
        'endDate': '2007-02-08',
        'members': 3176469,
        'episodes': 220,
        'rating': 'PG-13',
      });
      expect(anime.malId, 20);
      expect(anime.title, 'Naruto');
      expect(anime.images?['jpg']?.largeJImageUrl, 'https://cdn/naruto.jpg');
      expect(anime.aired?.from, '2002-10-03');
      expect(anime.aired?.to, '2007-02-08');
      expect(anime.members, 3176469);
    });

    test('missing images no longer throws (was Map.from(null)!)', () {
      final anime = JikanAnime.fromJson({'malId': 1, 'title': 'No Images'});
      expect(anime.images, isNull);
      expect(anime.malId, 1);
    });

    test('Jikan v4 full item still parses', () {
      final anime = JikanAnime.fromJson({
        'mal_id': 1,
        'url': 'https://myanimelist.net/anime/1',
        'images': {
          'jpg': {'image_url': 'https://a.jpg', 'large_image_url': 'https://al.jpg'},
        },
        'title': 'Cowboy Bebop',
        'title_english': 'Cowboy Bebop',
        'title_synonyms': [],
        'type': 'TV',
        'episodes': 26,
        'score': 8.33,
        'scored_by': 900000,
        'aired': {'from': '1998-04-03', 'to': '1999-04-24'},
        'genres': [
          {'mal_id': 1, 'name': 'Action'},
        ],
      });
      expect(anime.malId, 1);
      expect(anime.images?['jpg']?.largeJImageUrl, 'https://al.jpg');
      expect(anime.scoredBy, 900000);
      expect(anime.genres!.single.malId, 1);
      expect(anime.aired?.from, '1998-04-03');
    });
  });
}
