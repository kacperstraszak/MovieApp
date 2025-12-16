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
      final List<int> currentIds = finalMovies.map((e) => e.id).toList();

      void addUniqueMovies(List<Movie> candidates, int limit) {
        candidates.shuffle();
        for (var movie in candidates) {
          if (finalMovies.length >= totalCount) break;
          if (!currentIds.contains(movie.id)) {
            finalMovies.add(movie);
            currentIds.add(movie.id);
          }
        }
      }

      if (options.genreIds.isNotEmpty) {
        final int targetCount = (totalCount * 0.7).ceil();

        final genreData = await supabase
            .from('movies')
            .select()
            .filter('genre_ids', 'ov', options.genreIds)
            .order('vote_count', ascending: false)
            .limit(targetCount * 4);

        final List<Movie> genreMovies =
            (genreData as List).map((json) => Movie.fromJson(json)).toList();

        addUniqueMovies(genreMovies, targetCount);
      }

      int missingCount = totalCount - finalMovies.length;
      int discoveryTarget = (totalCount * 0.2).floor();

      if (missingCount > 0 &&
          discoveryTarget > 0 &&
          options.genreIds.isNotEmpty) {
        final discoveryData = await supabase
            .from('movies')
            .select()
            .not('genre_ids', 'ov', options.genreIds)
            .gte('vote_count', 600)
            .order('vote_average', ascending: false)
            .limit(discoveryTarget * 5);

        final List<Movie> discoveryMovies = (discoveryData as List)
            .map((json) => Movie.fromJson(json))
            .toList();

        addUniqueMovies(discoveryMovies, discoveryMovies.length);
      }

      missingCount = totalCount - finalMovies.length;
      if (missingCount > 0) {
        final fallbackData = await supabase
            .from('movies')
            .select()
            .order('popularity', ascending: false)
            .limit(missingCount + 20);

        final List<Movie> fallbackMovies =
            (fallbackData as List).map((json) => Movie.fromJson(json)).toList();

        addUniqueMovies(fallbackMovies, missingCount);
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
    double? rating,
  }) async {
    try {
      final groupId = ref.read(groupProvider).currentGroup?.id;
      final userId = supabase.auth.currentUser?.id;
      if (groupId == null || userId == null) return;

      removeMovie(movieId);

      await supabase.from('user_interactions').upsert(
        {
          'group_id': groupId,
          'user_id': userId,
          'movie_id': movieId,
          'interaction_type': type,
          'rating': rating,
        },
        onConflict: 'group_id,user_id,movie_id',
      );
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

class SearchMoviesNotifier extends Notifier<List<Movie>> {
  @override
  List<Movie> build() {
    return [];
  }

  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      state = [];
      return;
    }

    try {
      final data = await supabase
          .from('movies')
          .select()
          .ilike('title', '%$query%')
          .order('popularity', ascending: false)
          .limit(20);

      final movies =
          (data as List).map((json) => Movie.fromJson(json)).toList();
      state = movies;
    } catch (error) {
      state = [];
    }
  }

  void clearSearch() {
    state = [];
  }
}

final searchMoviesProvider =
    NotifierProvider<SearchMoviesNotifier, List<Movie>>(
  SearchMoviesNotifier.new,
);

final recommendationMoviesProvider =
    NotifierProvider<RecommendationMoviesNotifier, List<Movie>>(
  RecommendationMoviesNotifier.new,
);

final trendingMoviesProvider =
    NotifierProvider<TrendingMoviesNotifier, List<Movie>>(
  TrendingMoviesNotifier.new,
);
