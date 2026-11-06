import 'package:dal_commons/src/constants/constant.dart';
import 'package:dal_commons/src/model/dal/user_history.dart';
import 'package:dal_commons/src/services/html_parser.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:test/test.dart';

/// MAL's anime.php and manga.php side bars do not put the producers and the
/// magazines block at the same position, so the old hardcoded `.genre-link[4]`
/// index left the Magazines list empty. History had its own problems: MAL's
/// untyped history page only lists anime, and the entry links were only read
/// in their legacy `?id=` shape.
void main() {
  const sideBar = '''
<html><body>
  <div class="genre-link"><div class="genre-list">
    <a href="/genres.php">All</a>
  </div></div>
  <div class="genre-link"><div class="genre-list">
    <a href="/anime/genre/1/Action">Action</a>
  </div></div>
  <div class="genre-link"><div class="genre-list">
    <a href="/anime/genre/4/Drama">Drama</a>
  </div></div>
  <div class="genre-link"><div class="genre-list">
    <a href="/anime/theme/1/Gourmet">Gourmet</a>
  </div></div>
  <div class="genre-link"><div class="genre-list">
    <a href="/anime/producer/18/Toei_Animation">Toei Animation</a>
    <a href="/anime/producer/14/Sunrise">Sunrise</a>
  </div></div>
  <div class="genre-link"><div class="genre-list">
    <a href="/manga/magazine/1439/KakaoPage">KakaoPage</a>
    <a href="/manga/magazine/673/Naver_Webtoon">Naver Webtoon</a>
    <a href="/manga/magazine/1/Shonen_Jump_">Shonen Jump+</a>
  </div></div>
  <div class="genre-link"><div class="genre-list">
    <a href="/manga/demographic/1/Shounen">Shounen</a>
  </div></div>
</body></html>
''';

  group('parseMagazines', () {
    test('finds the magazines block even though it is not at index 4', () {
      final doc = html_parser.parse(sideBar);
      final magazines = HtmlParsers.parseMagazines(doc, ContentType.manga);

      expect(magazines['1439'], 'KakaoPage');
      expect(magazines['673'], 'Naver Webtoon');
      expect(magazines['1'], 'Shonen Jump');
      expect(magazines.values, isNot(contains('Action')),
          reason: 'genre links must not leak into the producer list');
    });

    test('still finds producers on anime.php', () {
      final doc = html_parser.parse(sideBar);
      final studios = HtmlParsers.parseMagazines(doc, ContentType.anime);

      expect(studios, {'18': 'Toei Animation', '14': 'Sunrise'});
    });

    test('accepts absolute links as well as relative ones', () {
      final doc = html_parser.parse('''
<div class="genre-link"><div class="genre-list">
  <a href="https://myanimelist.net/manga/magazine/26/Mag_Garden">Mag Garden</a>
</div></div>''');
      expect(HtmlParsers.parseMagazines(doc, ContentType.manga),
          {'26': 'Mag Garden'});
    });

    test('an empty page yields an empty map instead of throwing', () {
      expect(HtmlParsers.parseMagazines(html_parser.parse('<html></html>'),
          ContentType.manga), isEmpty);
    });
  });

  group('parseUserHistory', () {
    const legacyLinks = '''
<html><body><div class="history_content_wrapper"><table>
  <tr><td colspan="2"><div class="normal_header">Today <small>(2)</small></div></td></tr>
  <tr><td class="borderClass"><a href="/anime.php?id=58359"> Some Anime </a> ep. <strong>8</strong></td>
      <td class="borderClass" align="right">&nbsp;7 hours ago</td></tr>
  <tr><td class="borderClass"><a href="/manga.php?id=121"> One Piece </a> vol. <strong>100</strong></td>
      <td class="borderClass" align="right">&nbsp;Yesterday, 7:05 AM</td></tr>
</table></div></body></html>
''';

    test('reads the legacy ?id= links and keeps the requested category', () {
      final history = HtmlParsers.parseUserHistory(
          html_parser.parse(legacyLinks), 'anime');

      expect(history, hasLength(2));
      expect(history.first['id'], '58359');
      expect(history.first['title'], 'Some Anime');
      expect(history.first['history'], 'ep. 8');
      expect(history.first['time'], '7 hours ago');
      expect(history.map((e) => e['category']), everyElement('anime'),
          reason: 'the fetched page decides the category, not the link');
    });

    test('falls back to the link when no category was requested', () {
      final history =
          HtmlParsers.parseUserHistory(html_parser.parse(legacyLinks), '');
      expect(history.map((e) => e['category']), ['anime', 'manga']);
    });

    test('reads the modern /anime/{id}/Title links', () {
      final history = HtmlParsers.parseUserHistory(
          html_parser.parse('''
<div class="history_content_wrapper"><table>
  <tr><td class="borderClass"><a href="https://myanimelist.net/anime/21/One_Piece">One Piece</a> ep. <strong>1100</strong></td>
      <td class="borderClass" align="right">&nbsp;2 days ago</td></tr>
</table></div>'''), 'anime');

      expect(history, hasLength(1));
      expect(history.single['id'], '21');
      expect(history.single['category'], 'anime');
    });

    test('a page without a history section is empty rather than null', () {
      expect(
          HtmlParsers.parseUserHistory(
              html_parser.parse('<html><body><p>nope</p></body></html>'),
              'anime'),
          isEmpty);
    });

    test('the model tolerates an unknown category', () {
      final datum = Datum.fromJson({
        'id': '21',
        'title': 'One Piece',
        'category': 'novel',
      });
      expect(datum.category, isNull);
      expect(datum.id, '21');
    });
  });
}
