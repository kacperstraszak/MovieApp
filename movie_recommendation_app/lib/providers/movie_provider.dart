import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/models/recommendation_option.dart';
import 'package:movie_recommendation_app/providers/group_provider.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class TrendingMoviesNotifier extends Notifier<List<Movie>> {
  @override
  List<Movie> build() {
    _loadInitialMovies();
    return [];
  }

  Future<void> _loadInitialMovies() async {
    try {
      final data = await supabase
          .from('movies')
          .select()
          .order('popularity', ascending: false)
          .limit(30);

      final movies =
          (data as List).map((json) => Movie.fromJson(json)).toList();
      state = movies;
    } catch (error) {
      state = [];
    }
  }
}

final trendingMoviesProvider =
    NotifierProvider<TrendingMoviesNotifier, List<Movie>>(
  TrendingMoviesNotifier.new,
);

class RecommendationMoviesNotifier extends Notifier<List<Movie>> {
  @override
  List<Movie> build() {
    return [];
  }

  Future<void> loadMoviesBasedOnOptions(RecommendationOption options) async {
    try {
      final int totalCount = options.movieCount;
      final List<Movie> finalMovies = [];

      int genreTargetCount = 0;
      if (options.genreIds.isNotEmpty) {
        genreTargetCount = (totalCount * 0.75).ceil();
        final genreData = await supabase
            .from('movies')
            .select()
            .filter('genre_ids', 'ov', options.genreIds)
            .order('popularity', ascending: false)
            .limit(genreTargetCount);
        finalMovies.addAll(
            (genreData as List).map((json) => Movie.fromJson(json)).toList());
      }

      int missingCount = totalCount - finalMovies.length;
      if (missingCount > 0 && options.genreIds.isNotEmpty) {
        final otherData = await supabase
            .from('movies')
            .select()
            .not('genre_ids', 'ov', options.genreIds)
            .order('popularity', ascending: false)
            .limit(missingCount + 10);

        final otherMovies =
            (otherData as List).map((json) => Movie.fromJson(json)).toList();
        for (var movie in otherMovies) {
          if (finalMovies.length >= totalCount) break;
          if (!finalMovies.any((m) => m.id == movie.id)) finalMovies.add(movie);
        }
      }

      missingCount = totalCount - finalMovies.length;
      if (missingCount > 0) {
        final fallbackData = await supabase
            .from('movies')
            .select()
            .order('popularity', ascending: false)
            .limit(totalCount + 20);
        final fallbackMovies =
            (fallbackData as List).map((json) => Movie.fromJson(json)).toList();
        for (var movie in fallbackMovies) {
          if (finalMovies.length >= totalCount) break;
          if (!finalMovies.any((m) => m.id == movie.id)) finalMovies.add(movie);
        }
      }

      finalMovies.shuffle();
      state = finalMovies;
    } catch (error) {
      state = [];
    }
  }

  Future<void> recordInteraction({
    required int movieId,
    required String type, // 'like', 'dislike', 'not_seen'
    int? rating,
  }) async {
    try {
      final groupId = ref.read(groupProvider).currentGroup?.id;
      final userId = supabase.auth.currentUser?.id;
      if (groupId == null || userId == null) return;

      state = [
        for (final movie in state)
          if (movie.id != movieId) movie,
      ];

      await supabase.from('user_interactions').upsert({
        'group_id': groupId,
        'user_id': userId,
        'movie_id': movieId,
        'interaction_type': type,
        'rating': rating,
      });
    } catch (e) {
      print('Error recording interaction: $e');
    }
  }

  void removeMovie(int movieId) {
    state = [
      for (final movie in state)
        if (movie.id != movieId) movie,
    ];
  }

  Future<void> generateGroupCandidatesStub() async {
    final groupId = ref.read(groupProvider).currentGroup?.id;
    if (groupId == null) return;

    try {
      final interactions = await supabase
          .from('user_interactions')
          .select('movie_id')
          .eq('group_id', groupId)
          .eq('interaction_type', 'like');

      final List<int> movieIds = (interactions as List)
          .map((e) => e['movie_id'] as int)
          .toSet()
          .toList()
          .take(10)
          .toList();

      if (movieIds.isEmpty) return;

      final List<Map<String, dynamic>> inserts = movieIds
          .map((mid) => {
                'group_id': groupId,
                'movie_id': mid,
              })
          .toList();

      await supabase.from('group_candidates').delete().eq('group_id', groupId);
      await supabase.from('group_candidates').insert(inserts);
    } catch (e) {
      print('Error generating candidates: $e');
    }
  }
}

final recommendationMoviesProvider =
    NotifierProvider<RecommendationMoviesNotifier, List<Movie>>(
  RecommendationMoviesNotifier.new,
);

final candidatesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final groupId = ref.read(groupProvider).currentGroup?.id;
  if (groupId == null) return [];

  final data = await supabase
      .from('group_candidates')
      .select('id, movie:movies(*)')
      .eq('group_id', groupId);

  return List<Map<String, dynamic>>.from(data);
});

final voteActionProvider = Provider((ref) {
  return (int candidateId, int score) async {
    final userId = supabase.auth.currentUser?.id;
    final groupId = ref.read(groupProvider).currentGroup?.id;
    if (userId == null || groupId == null) return;

    await supabase.from('final_votes').upsert({
      'user_id': userId,
      'group_id': groupId,
      'candidate_id': candidateId,
      'score': score,
    }, onConflict: 'user_id, candidate_id');
  };
});

