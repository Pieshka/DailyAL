import 'commonV4.dart';

class Club implements DataUnion {
  int? malId;
  String ?name;
  String? url;
  Images? images;
  int? members;
  String ?category;
  String? created;
  String ?access;

  Club(
      {this.malId,
      this.name,
      this.url,
      this.images,
      this.members,
      this.category,
      this.created,
      this.access});

  Club.fromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    malId = pickJson(json, ['mal_id', 'malId']);
    name = pickJson(json, ['name', 'title']);
    url = json['url'];
    images = json['images'] != null ? Images.fromJson(json['images']) : null;
    members = pickJson(json, ['members', 'total_members']);
    category = json['category'];
    created = pickJson(json, ['created', 'created_at']);
    access = json['access'];
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mal_id'] = malId;
    data['name'] = name;
    data['url'] = url;
    data['images'] = images?.toJson();
    data['members'] = members;
    data['category'] = category;
    data['created'] = created;
    data['access'] = access;
    return data;
  }
}
