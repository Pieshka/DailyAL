import 'commonV4.dart';

class UserProfileV4 implements DataUnion {
  int? malId;
  String? username;
  String? url;
  Images ?images;
  String? lastOnline;
  String ?gender;
  String ?birthday;
  String ?location;
  String ?joined;
  Statistics? statistics;
  List<External>? external;

  UserProfileV4(
      {this.malId,
      this.username,
      this.url,
      this.images,
      this.lastOnline,
      this.gender,
      this.birthday,
      this.location,
      this.joined,
      this.statistics,
      this.external});

  UserProfileV4.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    malId = json['mal_id'] ?? json['malId'];
    // jikan-edge nests the flat Jikan v4 fields under a "profile" object.
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : json;
    username = profile['username'];
    url = profile['url'] ?? profile['profileUrl'];
    if (profile['images'] != null) {
      images = Images.fromJson(profile['images']);
    } else {
      images = Images.fromUrl(profile['avatarUrl']);
    }
    lastOnline = profile['last_online'] ?? profile['lastOnlineAt'];
    gender = profile['gender'];
    birthday = profile['birthday'];
    location = profile['location'];
    joined = profile['joined'] ?? profile['joinedAt'];
    statistics = json['statistics'] != null
        ? Statistics.fromJson(json['statistics'])
        : null;
    if (json['external'] != null) {
      external = [];
      json['external'].forEach((v) {
        external?.add(External.fromJson(v));
      });
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mal_id'] = malId;
    data['username'] = username;
    data['url'] = url;
    data['images'] = images?.toJson();
    data['last_online'] = lastOnline;
    data['gender'] = gender;
    data['birthday'] = birthday;
    data['location'] = location;
    data['joined'] = joined;
    data['statistics'] = statistics?.toJson();
    data['external'] = external?.map((v) => v.toJson()).toList();
    return data;
  }
}

class Statistics {
  AnimeStats? anime;
  MangaStats? manga;

  Statistics({this.anime, this.manga});

  Statistics.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    anime =
        json['anime'] != null ? AnimeStats.fromJson(json['anime']) : null;
    manga =
        json['manga'] != null ? MangaStats.fromJson(json['manga']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['anime'] = anime?.toJson();
    data['manga'] = manga?.toJson();
    return data;
  }
}

class AnimeStats {
  double? daysWatched;
  double? meanScore;
  int? watching;
  int? completed;
  int? onHold;
  int? dropped;
  int? planToWatch;
  int? totalEntries;
  int? rewatched;
  int? episodesWatched;

  AnimeStats(
      {this.daysWatched,
      this.meanScore,
      this.watching,
      this.completed,
      this.onHold,
      this.dropped,
      this.planToWatch,
      this.totalEntries,
      this.rewatched,
      this.episodesWatched});

  AnimeStats.fromJson(Map<String, dynamic> ?json) {
    if (json == null) return;
    // Accept both Jikan v4 snake_case and jikan-edge camelCase keys.
    daysWatched =
        double.tryParse('${pickJson(json, ['days_watched', 'daysWatched'])}');
    meanScore =
        double.tryParse('${pickJson(json, ['mean_score', 'meanScore'])}');
    watching = json['watching'];
    completed = json['completed'];
    onHold = pickJson(json, ['on_hold', 'onHold']);
    dropped = json['dropped'];
    planToWatch = pickJson(json, ['plan_to_watch', 'planToWatch']);
    totalEntries = pickJson(json, ['total_entries', 'totalEntries']);
    rewatched = json['rewatched'];
    episodesWatched =
        pickJson(json, ['episodes_watched', 'episodesWatched']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['days_watched'] = daysWatched;
    data['mean_score'] = meanScore;
    data['watching'] = watching;
    data['completed'] = completed;
    data['on_hold'] = onHold;
    data['dropped'] = dropped;
    data['plan_to_watch'] = planToWatch;
    data['total_entries'] = totalEntries;
    data['rewatched'] = rewatched;
    data['episodes_watched'] = episodesWatched;
    return data;
  }
}

class MangaStats {
  double? daysRead;
  double? meanScore;
  int? reading;
  int? completed;
  int? onHold;
  int? dropped;
  int? planToRead;
  int? totalEntries;
  int? reread;
  int? chaptersRead;
  int ?volumesRead;

  MangaStats(
      {this.daysRead,
      this.meanScore,
      this.reading,
      this.completed,
      this.onHold,
      this.dropped,
      this.planToRead,
      this.totalEntries,
      this.reread,
      this.chaptersRead,
      this.volumesRead});

  MangaStats.fromJson(Map<String, dynamic> ?json) {
    if (json == null) return;
    // Accept both Jikan v4 snake_case and jikan-edge camelCase keys.
    daysRead =
        double.tryParse('${pickJson(json, ['days_read', 'daysRead'])}');
    meanScore =
        double.tryParse('${pickJson(json, ['mean_score', 'meanScore'])}');
    reading = json['reading'];
    completed = json['completed'];
    onHold = pickJson(json, ['on_hold', 'onHold']);
    dropped = json['dropped'];
    planToRead = pickJson(json, ['plan_to_read', 'planToRead']);
    totalEntries = pickJson(json, ['total_entries', 'totalEntries']);
    reread = json['reread'];
    chaptersRead = pickJson(json, ['chapters_read', 'chaptersRead']);
    volumesRead = pickJson(json, ['volumes_read', 'volumesRead']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['days_read'] = daysRead;
    data['mean_score'] = meanScore;
    data['reading'] = reading;
    data['completed'] = completed;
    data['on_hold'] = onHold;
    data['dropped'] = dropped;
    data['plan_to_read'] = planToRead;
    data['total_entries'] = totalEntries;
    data['reread'] = reread;
    data['chapters_read'] = chaptersRead;
    data['volumes_read'] = volumesRead;
    return data;
  }
}

class External {
  String? name;
  String? url;

  External({this.name, this.url});

  External.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    name = json['name'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['url'] = url;
    return data;
  }
}
