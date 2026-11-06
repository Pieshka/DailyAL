class Picture {
  final String? medium;
  final String? large;

  Picture({this.large, this.medium});

  factory Picture.fromJson(Map<String, dynamic>? json) {
    return json != null
        ? Picture(large: _url(json["large"]), medium: _url(json["medium"]))
        : Picture();
  }

  /// A missing key used to become the literal string "null" through
  /// `toString()`, which then reached image loaders and notification image
  /// downloads as a bogus URL.
  static String? _url(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  Map<String, dynamic> toJson() {
    return {"medium": medium, "large": large};
  }
}
