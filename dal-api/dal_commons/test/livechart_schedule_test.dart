import 'package:html/parser.dart' as html_parser;
import 'package:dal_commons/src/services/html_parser.dart';
import 'package:test/test.dart';

/// Regression: LiveChart redesigned its schedule grid markup and the old
/// selectors matched nothing, which emptied the airing schedule and removed
/// every episode countdown in the app. The parser must handle both the
/// redesigned (2025+) and the legacy markup.
void main() {
  const newMarkup = '''
<html><body><main>
<article class="lc-anime-card-abs lc-anime-details-card" data-anime-id="13226">
  <div class="lc-anime-poster-overlay-host">
    <a class="lc-anime-poster-overlay-host__overlay lc-anime-details-card__poster-overlays__release-state"
       href="/anime/13226/schedules/16410">
      <div><strong>EP6</strong> · TV (JP)</div>
      <time data-controller="countdown" data-timestamp="1793975400"
            class="lc-text-countdown">~d ~~h ~~m ~~s</time>
    </a>
  </div>
  <footer class="lc-anime-details-card__footer">
    <a href="https://kusuriyanohitorigoto.jp/season3/" class="official-site logo lc-anime-details-card__footer__icon"></a>
    <a href="https://myanimelist.net/anime/61987" class="mal logo lc-anime-details-card__footer__icon shrink-0 rounded-full inline-block"></a>
    <a href="https://anilist.co/anime/195516" class="anilist logo lc-anime-details-card__footer__icon"></a>
    <a href="http://www.anime-planet.com/anime/x" class="anime-planet logo lc-anime-details-card__footer__icon"></a>
  </footer>
</article>
<article class="lc-anime-card-abs lc-anime-details-card" data-anime-id="99999">
  <!-- no countdown: finished/announced entry, must be skipped -->
  <footer class="lc-anime-details-card__footer">
    <a href="https://myanimelist.net/anime/1" class="mal logo"></a>
  </footer>
</article>
</main></body></html>
''';

  const oldMarkup = '''
<html><body>
<div class="anime-card">
  <div class="episode-countdown"><time data-timestamp="1700000000"></time></div>
  <div class="release-schedule-info">EP12 · OVA</div>
  <div class="related-links">
    <a href="https://myanimelist.net/anime/5114" class="mal-icon"></a>
    <a href="https://anilist.co/anime/5114" class="anilist-icon"></a>
  </div>
</div>
</body></html>
''';

  group('parseLiveChartSchedule', () {
    test('parses the redesigned LiveChart grid', () {
      final doc = html_parser.parse(newMarkup);
      final entries = HtmlParsers.parseLiveChartSchedule(doc);
      expect(entries, hasLength(1),
          reason: 'cards without a countdown must be skipped');
      final entry = entries!.single;
      expect(entry['timestamp'], 1793975400);
      expect(entry['episode'], 6);
      final links = entry['relatedLinks'] as Map;
      expect(links['mal'], 'https://myanimelist.net/anime/61987');
      expect(links['anilist'], 'https://anilist.co/anime/195516');
      expect(links['anime-planet'],
          'http://www.anime-planet.com/anime/x');
      expect(links['official-site'],
          'https://kusuriyanohitorigoto.jp/season3/');
    });

    test('still parses the legacy LiveChart grid', () {
      final doc = html_parser.parse(oldMarkup);
      final entries = HtmlParsers.parseLiveChartSchedule(doc);
      expect(entries, hasLength(1));
      final entry = entries!.single;
      expect(entry['timestamp'], 1700000000);
      expect(entry['episode'], 12);
      final links = entry['relatedLinks'] as Map;
      expect(links['mal'], 'https://myanimelist.net/anime/5114');
      expect(links['anilist'], 'https://anilist.co/anime/5114');
    });

    test('null document yields null', () {
      expect(HtmlParsers.parseLiveChartSchedule(null), isNull);
    });
  });
}
