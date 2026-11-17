import 'package:dal_commons/src/model/anime/anime_graph.dart';
import 'package:test/test.dart';

void main() {
  group('AnimeGraph.fromJson', () {
    test('a null body (failed request) parses to an empty graph', () {
      final graph = AnimeGraph.fromJson(null);
      expect(graph.nodes, isEmpty);
      expect(graph.edges, isEmpty);
    });

    test('missing nodes/edges keys parse to empty lists', () {
      final graph = AnimeGraph.fromJson({});
      expect(graph.nodes, isEmpty);
      expect(graph.edges, isEmpty);
    });

    test('a graph with only nodes and no edges parses', () {
      final graph = AnimeGraph.fromJson({
        'nodes': [
          {'id': 1, 'title': 'Sword Art Online', 'mean': 7.7}
        ]
      });
      expect(graph.nodes, hasLength(1));
      expect(graph.edges, isEmpty);
    });
  });

  group('GraphEdge.fromJson', () {
    test('a known relation type parses', () {
      final edge = GraphEdge.fromJson({
        'source': 1,
        'target': 2,
        'relation_type': 'sequel',
      });
      expect(edge.relationType, GRelationType.sequel);
    });

    test('an unknown relation type falls back to other', () {
      final edge = GraphEdge.fromJson({
        'source': 1,
        'target': 2,
        'relation_type': 'manga',
      });
      expect(edge.relationType, GRelationType.other,
          reason: 'a new upstream relation type must not throw and blank '
              'the whole graph');
    });

    test('a missing relation type falls back to other', () {
      final edge = GraphEdge.fromJson({'source': 1, 'target': 2});
      expect(edge.relationType, GRelationType.other);
    });
  });

  group('GStartSeason.fromJson', () {
    test('a known season parses', () {
      final season = GStartSeason.fromJson({'year': 2022, 'season': 'fall'});
      expect(season.season, GSeason.FALL);
    });

    test('a missing season stays null', () {
      final season = GStartSeason.fromJson({'year': 2022});
      expect(season.season, isNull,
          reason: 'a node without a season must not throw');
    });
  });
}
