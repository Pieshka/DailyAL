import 'commonV4.dart';

class AnimeVideoV4 implements DataUnion {
  List<Promo>? promo;
  List<Episodes>? episodes;
  List<MusicVideos>? musicVideos;

  AnimeVideoV4({this.promo, this.episodes, this.musicVideos});

  AnimeVideoV4.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    final promos = json['promo'] ?? json['promos'];
    if (promos != null) {
      promo = [];
      promos.forEach((v) {
        promo!.add(Promo.fromJson(v));
      });
    }
    if (json['episodes'] != null) {
      episodes = [];
      json['episodes'].forEach((v) {
        episodes!.add(Episodes.fromJson(v));
      });
    }
    final mvs = json['music_videos'] ?? json['musicVideos'];
    if (mvs != null) {
      musicVideos = [];
      mvs.forEach((v) {
        musicVideos!.add(MusicVideos.fromJson(v));
      });
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (promo != null) {
      data['promo'] = promo!.map((v) => v.toJson()).toList();
    }
    if (episodes != null) {
      data['episodes'] = episodes!.map((v) => v.toJson()).toList();
    }
    if (musicVideos != null) {
      data['music_videos'] = musicVideos!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Promo {
  String? title;
  Trailer? trailer;

  Promo({this.title, this.trailer});

  Promo.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    title = json['title'];
    if (json['trailer'] != null) {
      trailer = Trailer.fromJson(json['trailer']);
    } else if (json['videoUrl'] != null || json['imageUrl'] != null) {
      // jikan-edge flattens promos: {title, videoUrl, imageUrl}
      trailer = Trailer(
        youtubeId: _youtubeId(json['videoUrl']),
        url: json['videoUrl'],
        embedUrl: json['videoUrl'],
        images: Jpg(imageUrl: json['imageUrl']),
      );
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    if (trailer != null) {
      data['trailer'] = trailer?.toJson();
    }
    return data;
  }
}

class Trailer {
  String? youtubeId;
  String? url;
  String? embedUrl;
  Jpg? images;

  Trailer({this.youtubeId, this.url, this.embedUrl, this.images});

  Trailer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    youtubeId = json['youtube_id'];
    url = json['url'];
    embedUrl = json['embed_url'];
    images = json['images'] != null ? Jpg.fromJson(json['images']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['youtube_id'] = youtubeId;
    data['url'] = url;
    data['embed_url'] = embedUrl;
    if (images != null) {
      data['images'] = images?.toJson();
    }
    return data;
  }
}

class Episodes {
  int? malId;
  String? url;
  String? title;
  String? episode;
  Images? images;

  Episodes({this.malId, this.url, this.title, this.episode, this.images});

  Episodes.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    malId = pickJson(json, ['mal_id', 'malId']);
    url = json['url'];
    title = json['title'];
    final ep = pickJson(json, ['episode', 'episode_id']);
    episode = ep?.toString();
    images = json['images'] != null
        ? Images.fromJson(json['images'])
        : Images.fromUrl(json['imageUrl']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mal_id'] = malId;
    data['url'] = url;
    data['title'] = title;
    data['episode'] = episode;
    if (images != null) {
      data['images'] = images?.toJson();
    }
    return data;
  }
}

class MusicVideos {
  String? title;
  Trailer? video;
  Meta? meta;

  MusicVideos({this.title, this.video, this.meta});

  MusicVideos.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    title = json['title'];
    video = json['video'] != null ? Trailer.fromJson(json['video']) : null;
    meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    if (video != null) {
      data['video'] = video?.toJson();
    }
    if (meta != null) {
      data['meta'] = meta?.toJson();
    }
    return data;
  }
}

class Meta {
  String? title;
  String? author;

  Meta({this.title, this.author});

  Meta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    title = json['title'];
    author = json['author'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['author'] = author;
    return data;
  }
}

/// Extracts the YouTube id from a video URL (jikan-edge only gives the URL).
String? _youtubeId(dynamic videoUrl) {
  if (videoUrl is! String) return null;
  final match =
      RegExp(r'(?:v=|youtu\.be/|/embed/)([\w-]{6,12})').firstMatch(videoUrl);
  return match?.group(1);
}
