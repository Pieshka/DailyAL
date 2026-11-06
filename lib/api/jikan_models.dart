/// Models for Jikan API v4 responses
/// Specifically for anime statistics including score distribution

class JikanAnimeStatistics {
  final int? watching;
  final int? completed;
  final int? onHold;
  final int? dropped;
  final int? planToWatch;
  final int? total;
  final List<ScoreStatistics>? scores;

  JikanAnimeStatistics({
    this.watching,
    this.completed,
    this.onHold,
    this.dropped,
    this.planToWatch,
    this.total,
    this.scores,
  });

  factory JikanAnimeStatistics.fromJson(Map<String, dynamic> json) {
    // Jikan v4 puts the counters at the top level with snake_case keys;
    // jikan-edge nests them under "status" with camelCase keys.
    final status = json['status'] is Map
        ? Map<String, dynamic>.from(json['status'] as Map)
        : json;
    return JikanAnimeStatistics(
      watching: status['watching'] ?? status['inProgress'],
      completed: status['completed'],
      onHold: status['on_hold'] ?? status['onHold'],
      dropped: status['dropped'],
      planToWatch: status['plan_to_watch'] ?? status['planned'],
      total: status['total'],
      scores: json['scores'] != null
          ? (json['scores'] as List)
              .map((e) => ScoreStatistics.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'watching': watching,
      'completed': completed,
      'on_hold': onHold,
      'dropped': dropped,
      'plan_to_watch': planToWatch,
      'total': total,
      'scores': scores?.map((e) => e.toJson()).toList(),
    };
  }
}

class ScoreStatistics {
  final int? score;
  final int? votes;
  final double? percentage;

  ScoreStatistics({
    this.score,
    this.votes,
    this.percentage,
  });

  factory ScoreStatistics.fromJson(Map<String, dynamic> json) {
    return ScoreStatistics(
      score: json['score'],
      votes: json['votes'] ?? json['vote_count'],
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'votes': votes,
      'percentage': percentage,
    };
  }
}
