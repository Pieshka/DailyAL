import 'package:dal_commons/src/model/global/picture.dart';
import 'package:test/test.dart';

void main() {
  group('Picture.fromJson', () {
    test('missing keys stay null instead of becoming the string "null"', () {
      final picture = Picture.fromJson({
        'medium': 'https://cdn.myanimelist.net/images/anime/1/m.jpg',
      });
      expect(picture.medium,
          'https://cdn.myanimelist.net/images/anime/1/m.jpg');
      expect(picture.large, isNull,
          reason: 'a "null" URL used to be passed to image and notification '
              'loaders, so artwork silently failed');
    });

    test('null, empty and literal "null" values are all rejected', () {
      expect(Picture.fromJson({'large': null, 'medium': ''}).large, isNull);
      expect(Picture.fromJson({'large': 'null'}).large, isNull);
      expect(Picture.fromJson({'large': '  '}).large, isNull);
    });

    test('a missing object yields an empty picture', () {
      final picture = Picture.fromJson(null);
      expect(picture.large, isNull);
      expect(picture.medium, isNull);
    });

    test('both poster sizes are kept when present', () {
      final picture = Picture.fromJson({
        'medium': 'https://cdn.myanimelist.net/images/anime/1/19644.webp',
        'large': 'https://cdn.myanimelist.net/images/anime/1/19644l.webp',
      });
      expect(picture.large, endsWith('19644l.webp'));
      expect(picture.medium, endsWith('19644.webp'));
    });
  });
}
