import 'package:dal_api/services/anime_service.dart';
import 'package:test/test.dart';

Map<String, dynamic> anime(int id, {List<Map<String, dynamic>>? related}) {
  return {
    'id': id,
    'title': 'Anime $id',
    'main_picture': {'medium': 'm$id', 'large': 'l$id'},
    'mean': 7.0 + id,
    'media_type': 'tv',
    'status': 'finished_airing',
    'start_season': {'year': 2000 + id, 'season': 'spring'},
    'related_anime': related,
  };
}

Map<String, dynamic> rel(int target, String type) => {
      'node': {'id': target, 'title': 'Anime $target'},
      'relation_type': type,
      'relation_type_formatted': type,
    };

Future<Map<String, dynamic>?> Function(int id) fetcher(
        Map<int, Map<String, dynamic>> db) =>
    (id) async => db[id];

void main() {
  test('walks relations transitively and emits nodes/edges', () async {
    final db = {
      1: anime(1, related: [rel(2, 'sequel'), rel(3, 'prequel')]),
      2: anime(2, related: [rel(4, 'sequel')]),
      3: anime(3),
      4: anime(4),
    };
    final graph =
        await AnimeService.i.relatedGraph(1, fetchAnime: fetcher(db));
    final nodes = (graph['nodes'] as List).cast<Map<String, dynamic>>();
    final edges = (graph['edges'] as List).cast<Map<String, dynamic>>();
    expect(nodes.map((n) => n['id']), unorderedEquals([1, 2, 3, 4]));
    expect(
      edges.map((e) => '${e['source']}>${e['target']}:${e['relation_type']}'),
      unorderedEquals(['1>2:sequel', '1>3:prequel', '2>4:sequel']),
    );
    // The node payload keeps the fields the app's graph renders.
    final root = nodes.firstWhere((n) => n['id'] == 1);
    expect(root['mean'], 8.0);
    expect(root['start_season'], {'year': 2001, 'season': 'spring'});
    expect(root['main_picture'], {'medium': 'm1', 'large': 'l1'});
  });

  test('skips character relations and non-root other links', () async {
    final db = {
      1: anime(1, related: [rel(2, 'character'), rel(3, 'other')]),
      2: anime(2, related: [rel(4, 'other')]),
      3: anime(3),
      4: anime(4),
    };
    final graph =
        await AnimeService.i.relatedGraph(1, fetchAnime: fetcher(db));
    final nodes = (graph['nodes'] as List).cast<Map<String, dynamic>>();
    final edges = (graph['edges'] as List).cast<Map<String, dynamic>>();
    expect(nodes.map((n) => n['id']), unorderedEquals([1, 3]));
    expect(edges.map((e) => '${e['source']}>${e['target']}'), ['1>3']);
  });

  test('survives cycles and shared targets without duplicates', () async {
    final db = {
      1: anime(1, related: [rel(2, 'sequel'), rel(3, 'prequel')]),
      2: anime(2, related: [rel(3, 'side_story'), rel(1, 'prequel')]),
      3: anime(3, related: [rel(2, 'side_story')]),
    };
    final graph =
        await AnimeService.i.relatedGraph(1, fetchAnime: fetcher(db));
    final nodes = (graph['nodes'] as List).cast<Map<String, dynamic>>();
    final edges = (graph['edges'] as List).cast<Map<String, dynamic>>();
    final keys =
        edges.map((e) => '${e['source']}>${e['target']}:${e['relation_type']}');
    expect(keys.toSet().length, edges.length); // no duplicate edges
    // 2 and 3 become nodes in the same level, so the links between them
    // (and back to the root) are dropped, matching the hosted service.
    expect(keys.toSet(),
        unorderedEquals({'1>2:sequel', '1>3:prequel'}));
    expect(nodes.map((n) => n['id']), unorderedEquals([1, 2, 3]));
  });

  test('root with no relations yields a single node', () async {
    final graph =
        await AnimeService.i.relatedGraph(9, fetchAnime: fetcher({9: anime(9)}));
    expect((graph['nodes'] as List).length, 1);
    expect(graph['edges'], isEmpty);
  });

  test('a missing anime yields an empty graph instead of crashing', () async {
    final graph = await AnimeService.i.relatedGraph(
        1, fetchAnime: (id) async => null);
    expect(graph['nodes'], isEmpty);
    expect(graph['edges'], isEmpty);
  });
}
