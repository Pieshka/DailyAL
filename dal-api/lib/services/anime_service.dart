import 'dart:math';

import 'package:dal_api/client/http_connect.dart';
import 'package:dal_api/handlers/environemt.dart';
import 'package:dal_commons/commons.dart';

/// Serves the features the app previously delegated to the hosted Rust DAL
/// (related-anime graph + search autocomplete) straight from public APIs, so
/// the app works without any external DAL deployment.
class AnimeService {
  AnimeService._();
  static AnimeService i = AnimeService._();

  /// Anime details fetched while building graphs, kept in memory for the
  /// process lifetime so revisiting a graph does not re-fetch the same anime
  /// (the hosted service does the same in its cache tier).
  final Map<int, Map<String, dynamic>> _animeCache = {};

  static const String _animeFields =
      'alternative_titles,mean,media_type,status,start_season,related_anime';

  /// Relation types that belong in the graph. "character" is never included,
  /// and "other" only from the root anime (mirrors the hosted service).
  static const _validRelations = {
    'alternative_setting',
    'sequel',
    'prequel',
    'alternative_version',
    'side_story',
    'parent_story',
    'summary',
    'full_story',
    'spin_off',
  };

  Future<Map<String, dynamic>?> _fetchAnime(int id) async {
    final cached = _animeCache[id];
    if (cached != null) return cached;
    final anime = await HttpConnect.retryGetChecked(
      '${Constants.endPoint}anime/$id?fields=$_animeFields',
      {Constants.clientHeader: Environment.i.malClientId ?? ''},
    );
    if (anime == null) return null;
    final animeId = anime['id'];
    if (animeId is int) {
      _animeCache[animeId] = anime;
    }
    return anime;
  }

  /// Builds `{nodes: [...], edges: [...]}` for [rootId] in the same shape the
  /// hosted service returns. Throws when the upstream fails; the handler
  /// then answers with the generic error payload.
  Future<Map<String, dynamic>> relatedGraph(
    int rootId, {
    Future<Map<String, dynamic>?> Function(int id)? fetchAnime,
  }) async {
    final fetch = fetchAnime ?? _fetchAnime;
    final nodeIds = <int>{};
    final nodes = <Map<String, dynamic>>[];
    final edgeKeys = <String>{};
    final edges = <Map<String, dynamic>>[];

    void addNode(Map<String, dynamic> anime) {
      final id = anime['id'];
      if (id is! int || nodeIds.contains(id)) return;
      nodeIds.add(id);
      final picture = anime['main_picture'];
      final season = anime['start_season'];
      nodes.add({
        'id': id,
        'title': anime['title'],
        'main_picture': picture is Map
            ? {'medium': picture['medium'], 'large': picture['large']}
            : null,
        'mean': anime['mean'],
        'media_type': anime['media_type'],
        'status': anime['status'],
        'start_season': season is Map
            ? {'year': season['year'], 'season': season['season']}
            : null,
      });
    }

    List<Map<String, dynamic>> validEdges(
        int id, dynamic relatedAnime, bool includeOthers) {
      if (relatedAnime is! List) return [];
      return relatedAnime
          .map((entry) {
            final node = entry is Map ? entry['node'] : null;
            final relationType = entry is Map ? entry['relation_type'] : null;
            final target = node is Map ? node['id'] : null;
            if (target is! int || relationType is! String) return null;
            final allowed = _validRelations.contains(relationType) ||
                (includeOthers && relationType == 'other');
            if (!allowed) return null;
            return <String, dynamic>{
              'source': id,
              'target': target,
              'relation_type': relationType,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    void addEdge(Map<String, dynamic> edge) {
      final key = '${edge['source']}-${edge['target']}-${edge['relation_type']}';
      if (!edgeKeys.add(key)) return;
      edges.add(edge);
    }

    Future<void> visit(int id, {required bool includeOthers}) async {
      final anime = await fetch(id);
      if (anime == null) return;
      addNode(anime);

      final unvisited = validEdges(id, anime['related_anime'], includeOthers)
          .where((edge) => !nodeIds.contains(edge['target']))
          .toList();

      // Fetch the unvisited targets five at a time, like the hosted service.
      final fetched = <Map<String, dynamic>>[];
      for (var start = 0; start < unvisited.length; start += 5) {
        final end = min(start + 5, unvisited.length);
        final batch = await Future.wait(unvisited
            .sublist(start, end)
            .map((edge) => fetch(edge['target'] as int)));
        fetched.addAll(batch.whereType<Map<String, dynamic>>().toList());
      }
      // Drop duplicate fetches (two parents sharing one related anime) so the
      // same anime's relations are not walked twice.
      final fetchedAnime = <int>{};
      final uniqueFetched = fetched
          .where((anime) {
            final id = anime['id'];
            return id is int && fetchedAnime.add(id);
          })
          .toList();
      uniqueFetched.forEach(addNode);
      unvisited.forEach(addEdge);

      // Continue walking from the newly added anime, one level at a time.
      final next = uniqueFetched
          .expand((anime) =>
              validEdges(anime['id'] as int, anime['related_anime'], false))
          .where((edge) => !nodeIds.contains(edge['target']))
          .toList();
      for (final edge in next) {
        addEdge(edge);
        await visit(edge['target'] as int, includeOthers: false);
      }
    }

    await visit(rootId, includeOthers: true);
    return {'nodes': nodes, 'edges': edges};
  }

  /// Search suggestions for autocomplete. The Jikan mirror serves one MAL
  /// search page per request (it rejects `limit`), so the results are trimmed
  /// after the fact.
  Future<List<Map<String, dynamic>>> autoComplete(
    String query, {
    int limit = 10,
    Future<Map<String, dynamic>?> Function(
            String url, Map<String, String> headers) fetch =
        HttpConnect.retryGetChecked,
  }) async {
    final data = await fetch(
      '${Constants.jikanV4}anime?q=${Uri.encodeQueryComponent(query)}',
      {},
    );
    final results = data?['data'];
    if (results is! List) return [];
    return results.take(limit).map((entry) {
      final item = entry is Map ? entry : const <String, dynamic>{};
      final malId = item['malId'] ?? item['mal_id'] ?? item['id'];
      final picture = item['imageUrl'] ?? item['image'];
      return <String, dynamic>{
        'title': item['title'] ?? '',
        'picture': picture,
        'year': _yearFrom(item['year'] ?? item['startDate']),
        // The app model expects a string id (int.tryParse on the UI side).
        'malId': malId?.toString(),
        'mean': item['score'] ?? item['mean'],
        'synonyms': '',
      };
    }).toList();
  }

  int? _yearFrom(dynamic value) {
    if (value is int) return value;
    if (value is String && value.length >= 4) {
      return int.tryParse(value.substring(0, 4));
    }
    return null;
  }
}
