class GroupRecommendation {
  final String id;
  final String groupId;
  final int movieId;
  final double score;
  final int position;
  final int? voteCount;
  final double? avgRating;
  final double? consensusScore;
  final bool isFinal;

  GroupRecommendation({
    required this.id,
    required this.groupId,
    required this.movieId,
    required this.score,
    required this.position,
    this.voteCount,
    this.avgRating,
    this.consensusScore,
    required this.isFinal,
  });

  factory GroupRecommendation.fromJson(Map<String, dynamic> j) => GroupRecommendation(
        id: j['id'] as String,
        groupId: j['group_id'] as String,
        movieId: j['movie_id'] as int,
        score: (j['score'] is num) ? (j['score'] as num).toDouble() : double.parse(j['score'].toString()),
        position: j['position'] as int,
        voteCount: j['vote_count'] == null ? null : (j['vote_count'] as int),
        avgRating: j['avg_rating'] == null ? null : (j['avg_rating'] as num).toDouble(),
        consensusScore: j['consensus_score'] == null ? null : (j['consensus_score'] as num).toDouble(),
        isFinal: j['is_final'] as bool? ?? false,
      );
}