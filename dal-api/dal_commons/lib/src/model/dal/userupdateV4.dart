import 'commonV4.dart';

class UserUpdateList implements DataUnion {
  List<UserUpdate>? data;

  UserUpdateList({this.data});

  UserUpdateList.fromJson(dynamic json) {
    if (json == null) return;
    var _data = [];
    data = [];
    if (json is List) {
      _data = json;
    } else if (json['data'] != null) {
      _data = json['data'];
    }
    for (var v in _data) {
      data?.add(UserUpdate.fromJson(v));
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['data'] = this.data?.map((v) => v.toJson()).toList();
    return data;
  }
}

class UserUpdate {
  UserV4? user;
  double? score;
  String? status;
  int? episodesSeen;
  int? episodesTotal;
  int? volumesRead;
  int? volumesTotal;
  int? chaptersRead;
  int? chaptersTotal;
  String? date;

  UserUpdate(
      {this.user,
      this.score,
      this.status,
      this.episodesSeen,
      this.episodesTotal,
      this.volumesRead,
      this.volumesTotal,
      this.chaptersRead,
      this.chaptersTotal,
      this.date});

  UserUpdate.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    if (json['user'] != null) {
      user = UserV4.fromJson(json['user']);
    } else if (json['username'] != null) {
      // Jikan v4 and jikan-edge expose the updater flat in the entry.
      user = UserV4(
        username: json['username'],
        url: json['user_url'] ?? json['url'],
        images: json['images'] != null
            ? Images.fromJson(json['images'])
            : Images.fromUrl(json['imageUrl']),
      );
    }
    score = double.tryParse('${json['score']}');
    status = json['status'];
    // jikan-edge names progress/total instead of episodes_seen/episodes_total.
    episodesSeen = pickJson(json, ['episodes_seen', 'progress']);
    episodesTotal = pickJson(json, ['episodes_total', 'total']);
    volumesRead = json['volumes_read'];
    volumesTotal = json['volumes_total'];
    chaptersRead = json['chapters_read'];
    chaptersTotal = json['chapters_total'];

    date = json['date'] ?? json['date_updated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user'] = user?.toJson();
    data['score'] = score;
    data['status'] = status;
    data['episodes_seen'] = episodesSeen;
    data['episodes_total'] = episodesTotal;
    data['volumes_read'] = volumesRead;
    data['volumes_total'] = volumesTotal;
    data['chapters_read'] = chaptersRead;
    data['chapters_total'] = chaptersTotal;
    data['date'] = date;
    return data;
  }
}
