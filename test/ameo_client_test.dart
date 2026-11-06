import 'package:dailyanimelist/features/ameo/ameo_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> sampleBody() => {
      'animeData': {
        '21': {
          'title': 'Naruto',
          'main_picture': {'large': 'https://cdn/naruto.jpg'}
        },
        '11757': {
          'title': 'Mononoke Hime',
          'main_picture': {'medium': 'https://cdn/mononoke.jpg'}
        },
        '5114': {'title': 'Fullmetal Alchemist: Brotherhood'},
      },
      'recommendations': [
        {
          'animeId': 11757,
          'score': 8.2,
          'predictedRating': 8.75,
          'topContributors': [
            {'animeId': 21, 'userRating': 9, 'ratingDelta': 0.42},
            {'animeId': 11757, 'userRating': 5},
            {'animeId': 5114},
          ],
        },
        {'animeId': 999999, 'predictedRating': 7.0},
      ],
      'topContributors': {
        '11757': [
          {'animeId': 21, 'userRating': 9, 'ratingDelta': 0.42},
        ]
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AmeoClient.decode', () {
    test('decodes recommendations with predicted rating and contributors', () {
      final items = AmeoClient().decode(sampleBody());
      expect(items.length, 1,
          reason: 'recommendations without metadata must be skipped');
      final item = items.first;
      expect(item.id, 11757);
      expect(item.title, 'Mononoke Hime');
      expect(item.image, 'https://cdn/mononoke.jpg');
      // The UI score must be the predicted rating, not the ranking score.
      expect(item.score, 8.75);
      expect(item.dailyAlNode, isNotNull);
      expect(item.dailyAlNode!.content!.id, 11757);
      // Contributors: self-reference skipped, title falls back to metadata.
      expect(item.contributors.map((e) => e.id), <int>[21, 5114]);
      expect(item.contributors[1].title, 'Fullmetal Alchemist: Brotherhood');
      expect(item.contributors.first.userRating, 9.0);
      expect(item.contributors.first.ratingDelta, 0.42);
    });

    test('a missing prediction stays missing (never the MAL mean score)', () {
      final items = AmeoClient().decode({
        'animeData': {
          '21': {'title': 'Naruto'}
        },
        'recommendations': [
          {'animeId': 21, 'score': 8.2}
        ],
      });
      expect(items.single.score, isNull);
    });

    test('malformed payloads raise FormatException, not type crashes', () {
      expect(() => AmeoClient().decode({}), throwsFormatException);
      expect(
        () => AmeoClient().decode({'animeData': [], 'recommendations': {}}),
        throwsFormatException,
      );
    });

    test('numeric-string ids and alternate keys are tolerated', () {
      final items = AmeoClient().decode({
        'animeData': {
          '21': {'title': 'Naruto'}
        },
        'recommendations': [
          {'id': '21', 'predicted_score': '7.5'}
        ],
      });
      expect(items.single.id, 21);
      expect(items.single.score, 7.5);
    });
  });

  group('AmeoSettings', () {
    test('round-trips through SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const settings = AmeoSettings(
        model: 'legacy',
        includeExtraSeasons: true,
        includeMusic: true,
        logitWeight: 0.25,
        nicheBoostFactor: 0.75,
      );
      await settings.save(prefs);
      final restored = AmeoSettings.fromPrefs(prefs);
      expect(restored.model, 'legacy');
      expect(restored.includeExtraSeasons, isTrue);
      expect(restored.includeMusic, isTrue);
      expect(restored.includeMovies, isTrue);
      expect(restored.logitWeight, 0.25);
      expect(restored.nicheBoostFactor, 0.75);
    });

    test('defaults are used when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = AmeoSettings.fromPrefs(prefs);
      expect(settings.model, '2026-logq');
      expect(settings.filterPlanToWatch, isTrue);
      expect(settings.logitWeight, 0.6);
    });

    test('copyWith keeps unspecified fields unchanged', () {
      const base = AmeoSettings();
      final updated = base.copyWith(model: '2025-jax', includeMovies: false);
      expect(updated.model, '2025-jax');
      expect(updated.includeMovies, isFalse);
      expect(updated.includeONAsOVAspecials,
          base.includeONAsOVAspecials);
      expect(updated.logitWeight, base.logitWeight);
    });
  });

  group('safeAmeoError', () {
    test('redacts credentials while preserving other diagnostics', () {
      final redacted = safeAmeoError(
        'failed access_token=supersecret; body={"ok":true}',
      );
      expect(redacted, contains('access_token=[redacted]'));
      expect(redacted, isNot(contains('supersecret')));
      expect(redacted, contains('body={"ok":true}'));
    });
  });
}
