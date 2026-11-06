import 'dart:convert';

import 'package:dailyanimelist/api/malapi.dart';
import 'package:dailyanimelist/api/maluser.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/user/user.dart';
import 'package:dal_commons/dal_commons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Isolated Ameo/Sprout client and data models. Kept free of UI/localization
/// concerns so request, decoding, and caching logic can be unit tested.
class AmeoContributor {
  final int id;
  final String title;
  final double? userRating;
  final double? ratingDelta;

  const AmeoContributor(
      {required this.id,
      required this.title,
      this.userRating,
      this.ratingDelta});
}

class AmeoAnime {
  final int id;
  final String title;
  final String image;
  final double? score;
  final BaseNode? dailyAlNode;
  final List<AmeoContributor> contributors;

  const AmeoAnime(
      {required this.id,
      required this.title,
      required this.image,
      this.score,
      this.dailyAlNode,
      this.contributors = const []});

  factory AmeoAnime.fromJson(int id, Map<String, dynamic> json, dynamic rec,
      {Map<int, Map<String, dynamic>>? allMetadata,
      List<dynamic> rawContributors = const []}) {
    final picture = json['main_picture'];
    final image = picture is Map
        ? (picture['large'] ?? picture['medium'] ?? '').toString()
        : '';
    final title = (json['title'] ?? json['title_english'] ?? 'Anime #$id')
        .toString();
    // Sprout's `score` is a ranking score, not the predicted rating shown in
    // the UI. Prefer the explicit prediction fields and keep ranking score
    // separate.
    final rawScore = rec is Map
        ? (rec['predictedRating'] ??
            rec['predicted_rating'] ??
            rec['predictedScore'] ??
            rec['predicted_score'])
        : null;
    final BaseNode node = BaseNode.fromJson(
      <String, dynamic>{'node': <String, dynamic>{...json, 'id': id}},
      category: 'anime',
    );
    final contributors = <AmeoContributor>[];
    for (final raw in rawContributors) {
      if (raw is! Map) continue;
      final rawId = raw['animeId'] ?? raw['anime_id'] ?? raw['id'] ?? raw['malId'];
      final contributorId = rawId is num
          ? rawId.toInt()
          : int.tryParse(rawId?.toString() ?? '');
      if (contributorId == null || contributorId == id) continue;
      final meta = allMetadata?[contributorId];
      final contributorTitle = (raw['title'] ??
              raw['animeTitle'] ??
              raw['name'] ??
              meta?['title'] ??
              'Anime #$contributorId')
          .toString();
      final rating = raw['userRating'] ?? raw['user_rating'];
      final delta = raw['ratingDelta'] ?? raw['rating_delta'];
      contributors.add(AmeoContributor(
          id: contributorId,
          title: contributorTitle,
          userRating: rating is num
              ? rating.toDouble()
              : double.tryParse(rating?.toString() ?? ''),
          ratingDelta: delta is num
              ? delta.toDouble()
              : double.tryParse(delta?.toString() ?? '')));
    }
    // A missing prediction must remain missing; MAL's mean score is a
    // different metric.
    final predictedScore = rawScore is num
        ? rawScore.toDouble()
        : double.tryParse(rawScore?.toString() ?? '');
    return AmeoAnime(
        id: id,
        title: title,
        image: image,
        score: predictedScore,
        dailyAlNode: node,
        contributors: contributors);
  }
}

class AmeoSettings {
  final String model;
  final bool includeExtraSeasons,
      includeONAsOVAspecials,
      includeMovies,
      includeMusic,
      filterPlanToWatch;
  final double logitWeight, nicheBoostFactor;

  const AmeoSettings(
      {this.model = '2026-logq',
      this.includeExtraSeasons = false,
      this.includeONAsOVAspecials = true,
      this.includeMovies = true,
      this.includeMusic = false,
      this.filterPlanToWatch = true,
      this.logitWeight = 0.6,
      this.nicheBoostFactor = 0.35});

  AmeoSettings copyWith(
          {String? model,
          bool? includeExtraSeasons,
          bool? includeONAsOVAspecials,
          bool? includeMovies,
          bool? includeMusic,
          bool? filterPlanToWatch,
          double? logitWeight,
          double? nicheBoostFactor}) =>
      AmeoSettings(
          model: model ?? this.model,
          includeExtraSeasons: includeExtraSeasons ?? this.includeExtraSeasons,
          includeONAsOVAspecials:
              includeONAsOVAspecials ?? this.includeONAsOVAspecials,
          includeMovies: includeMovies ?? this.includeMovies,
          includeMusic: includeMusic ?? this.includeMusic,
          filterPlanToWatch: filterPlanToWatch ?? this.filterPlanToWatch,
          logitWeight: logitWeight ?? this.logitWeight,
          nicheBoostFactor: nicheBoostFactor ?? this.nicheBoostFactor);

  factory AmeoSettings.fromPrefs(SharedPreferences p) => AmeoSettings(
      model: p.getString('ameo_model') ?? '2026-logq',
      includeExtraSeasons: p.getBool('ameo_extra_seasons') ?? false,
      includeONAsOVAspecials: p.getBool('ameo_ovas') ?? true,
      includeMovies: p.getBool('ameo_movies') ?? true,
      includeMusic: p.getBool('ameo_music') ?? false,
      filterPlanToWatch: p.getBool('ameo_filter_ptw') ?? true,
      logitWeight: p.getDouble('ameo_logit_weight') ?? 0.6,
      nicheBoostFactor: p.getDouble('ameo_niche_boost') ?? 0.35);

  Future<void> save(SharedPreferences p) async {
    await p.setString('ameo_model', model);
    await p.setBool('ameo_extra_seasons', includeExtraSeasons);
    await p.setBool('ameo_ovas', includeONAsOVAspecials);
    await p.setBool('ameo_movies', includeMovies);
    await p.setBool('ameo_music', includeMusic);
    await p.setBool('ameo_filter_ptw', filterPlanToWatch);
    await p.setDouble('ameo_logit_weight', logitWeight);
    await p.setDouble('ameo_niche_boost', nicheBoostFactor);
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'includeExtraSeasons': includeExtraSeasons,
        'includeONAsOVAsSpecials': includeONAsOVAspecials,
        'includeMovies': includeMovies,
        'includeMusic': includeMusic,
        'filterPlanToWatch': filterPlanToWatch,
        'logitWeight': logitWeight,
        'nicheBoostFactor': nicheBoostFactor,
        'popularityAttenuationFactor': 0.0008,
        'excludedIds': <int>[],
        'excludedGenreIds': <int>[]
      };
}

class AmeoRequestException implements Exception {
  final String diagnostics;
  const AmeoRequestException(this.diagnostics);
}

class AmeoClient {
  static const endpoint = 'https://anime.ameo.dev/recommendation/recommendation';
  static const ttl = Duration(hours: 6);

  Future<List<AmeoAnime>> recommend(String username, AmeoSettings settings,
      {bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'ameo_cache_' +
        base64Url.encode(utf8.encode(username + '|' + jsonEncode(settings.toJson())));
    final cached = prefs.getString(cacheKey);
    final cachedAt = prefs.getInt(cacheKey + '_at') ?? 0;
    if (!force &&
        cached != null &&
        DateTime.now().millisecondsSinceEpoch - cachedAt < ttl.inMilliseconds) {
      try {
        final cachedJson = jsonDecode(cached);
        if (cachedJson is Map<String, dynamic>) {
          final cachedItems = decode(cachedJson);
          await _mergeCachedListStatuses(cachedItems);
          return cachedItems;
        }
      } catch (_) {
        // Ignore corrupted cache and fall through to a fresh network request.
      }
      await prefs.remove(cacheKey);
      await prefs.remove(cacheKey + '_at');
    }
    final watch = Stopwatch()..start();
    var phase = 'request';
    var statusCode = 0;
    var contentType = '';
    var responseBody = '';
    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: const {
              'content-type': 'application/json; charset=UTF-8',
              'origin': 'https://anime.ameo.dev',
              'user-agent': 'DailyAL-Modif (Ameo integration)',
            },
            body: jsonEncode({
              'dataSource': {'type': 'username', 'username': username},
              'availableAnimeMetadataIDs': <int>[],
              'excludedRankingAnimeIDs': <int>[],
              'excludedGenreIDs': <int>[],
              'modelName': settings.model,
              'includeContributors': true,
              'includeExtraSeasons': settings.includeExtraSeasons,
              'includeONAsOVAsSpecials': settings.includeONAsOVAspecials,
              'includeMovies': settings.includeMovies,
              'includeMusic': settings.includeMusic,
              'profileSource': 'mal',
              'filterPlanToWatch': settings.filterPlanToWatch,
              'logitWeight': settings.logitWeight,
              'nicheBoostFactor': settings.nicheBoostFactor,
              'popularityAttenuationFactor': 0.0008,
            }),
          )
          .timeout(const Duration(seconds: 30));
      statusCode = response.statusCode;
      contentType = response.headers['content-type'] ?? '';
      responseBody = response.body;
      if (statusCode < 200 || statusCode >= 300) {
        throw http.ClientException('Ameo HTTP $statusCode', Uri.parse(endpoint));
      }
      phase = 'json_decode';
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid Ameo response root');
      }
      phase = 'recommendation_decode';
      final result = decode(decoded);
      await _mergeCachedListStatuses(result);
      await prefs.setString(cacheKey, jsonEncode(decoded));
      await prefs.setInt(cacheKey + '_at', DateTime.now().millisecondsSinceEpoch);
      return result;
    } catch (e) {
      if (cached != null) {
        try {
          final staleJson = jsonDecode(cached);
          if (staleJson is Map<String, dynamic>) {
            final stale = decode(staleJson);
            if (stale.isNotEmpty) {
              await _mergeCachedListStatuses(stale);
              return stale;
            }
          }
        } catch (_) {
          // Invalid stale cache must not mask the original request failure.
        }
      }
      final diagnostics = [
        'endpoint=$endpoint',
        'method=POST',
        'phase=$phase',
        'http_status=${statusCode == 0 ? 'unavailable' : statusCode}',
        'elapsed_ms=${watch.elapsedMilliseconds}',
        'content_type=${contentType.isEmpty ? 'unavailable' : contentType}',
        'cache_available=${cached != null}',
        'exception_type=${e.runtimeType}',
        'message=${safeAmeoError(e.toString())}',
        if (responseBody.isNotEmpty) 'response_body=${safeAmeoError(responseBody)}',
      ].join('\n');
      throw AmeoRequestException(diagnostics);
    }
  }

  Future<void> _mergeCachedListStatuses(List<AmeoAnime> items) async {
    final nodes =
        items.map((item) => item.dailyAlNode).whereType<BaseNode>().toList();
    // Ameo recommendations are independent of the MAL list cache. Fetch a full
    // list snapshot once when recommended IDs have no cached status.
    await MalApi.mergeCachedMyListStatus(
      nodes,
      'anime',
      fetchIfMissing: true,
      refreshFromNetwork: true,
    );
  }

  List<AmeoAnime> decode(Map<String, dynamic> body) {
    final rawMetadata = body['animeData'];
    final rawRecommendations = body['recommendations'];
    if (rawMetadata is! Map || rawRecommendations is! List) {
      throw const FormatException(
          'Expected animeData object and recommendations array');
    }
    final metadata = <int, Map<String, dynamic>>{};
    rawMetadata.forEach((key, value) {
      final id = int.tryParse(key.toString());
      if (id != null && value is Map) {
        metadata[id] = Map<String, dynamic>.from(value);
      }
    });
    final result = <AmeoAnime>[];
    for (final rec in rawRecommendations) {
      final rawId = rec is Map ? (rec['animeId'] ?? rec['id'] ?? rec['malId']) : rec;
      final id = rawId is num ? rawId.toInt() : int.tryParse(rawId.toString());
      if (id == null || metadata[id] == null) continue;
      result.add(AmeoAnime.fromJson(id, metadata[id]!, rec,
          allMetadata: metadata,
          rawContributors: _contributorsFor(body, rec, id)));
    }
    return result;
  }

  List<dynamic> _contributorsFor(Map<String, dynamic> body, dynamic rec, int id) {
    if (rec is Map) {
      for (final key in [
        'topContributors',
        'contributors',
        'becauseYouWatched',
        'because_you_watched',
        'contributorAnimeIds'
      ]) {
        final value = rec[key];
        if (value is List) return value;
      }
    }
    final root = body['topContributors'] ?? body['contributors'];
    if (root is Map) {
      final value = root[id.toString()] ?? root[id];
      if (value is List) return value;
      if (value is Map) {
        final nested =
            value['topContributors'] ?? value['contributors'] ?? value['anime'];
        if (nested is List) return nested;
      }
    }
    if (root is List) {
      for (final item in root) {
        if (item is! Map) continue;
        final target = item['recommendedAnimeId'] ??
            item['recommendationId'] ??
            item['targetAnimeId'] ??
            item['recommended_anime_id'];
        if (target == id || target?.toString() == id.toString()) {
          final nested =
              item['topContributors'] ?? item['contributors'] ?? item['anime'];
          if (nested is List) return nested;
        }
      }
    }
    return const [];
  }
}

Future<String> resolveAmeoUsername(SharedPreferences prefs) async {
  final saved = (prefs.getString('ameo_username') ?? '').trim();
  if (saved.isNotEmpty) return saved;
  if (user.status != AuthStatus.AUTHENTICATED) return '';
  try {
    final profile = await MalUser.getUserInfo(fields: const ['name']);
    return profile?.name?.trim() ?? '';
  } catch (_) {
    // Keep the feature usable when the MAL profile cannot be resolved.
    return '';
  }
}

// Keep server response line breaks intact for full, copyable diagnostics
// while redacting credentials. replaceAllMapped is used because a plain
// replaceAll replacement string does not expand $1 group references here.
String safeAmeoError(String value) => value.replaceAllMapped(
      RegExp(
        r'(access_token|refresh_token|authorization)\s*[:=]\s*(?:"[^"]*"|[^,;\r\n]+)',
        caseSensitive: false,
      ),
      (match) => '${match[1]}=[redacted]',
    );
