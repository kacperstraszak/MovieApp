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
}

final recommendationMoviesProvider =
    NotifierProvider<RecommendationMoviesNotifier, List<Movie>>(
  RecommendationMoviesNotifier.new,
);


final trendingMoviesProvider =
    NotifierProvider<TrendingMoviesNotifier, List<Movie>>(
  TrendingMoviesNotifier.new,
);


