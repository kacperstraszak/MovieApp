import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/models/recommendation_option.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class MoviesNotifier extends Notifier<List<Movie>> {
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
          .order('release', ascending: false)
          .limit(30);

      final movies =
          (data as List).map((json) => Movie.fromJson(json)).toList();
      state = movies;
    } catch (error) {
      state = [];
    }
  }

  Future<void> loadMoviesBasedOnOptions(RecommendationOption options) async {
    try {
      final int totalCount = options.movieCount;
      final List<Movie> finalMovies = [];

      // filmy z wybranego gatunku 75% żeby nie robić bańki
      int genreTargetCount = 0;
      if (options.genreIds.isNotEmpty) {
        genreTargetCount = (totalCount * 0.75).ceil();

        final genreData = await supabase
            .from('movies')
            .select()
            .filter('genre_ids', 'ov', options.genreIds) // ov - overlaps część wspólna z wybranymi gatunkami
            .order('popularity', ascending: false)
            .limit(genreTargetCount);

        final genreMovies =
            (genreData as List).map((json) => Movie.fromJson(json)).toList();
        finalMovies.addAll(genreMovies);
      }

      // pozostałe filmy spoza wybranych gatunków
      int missingCount = totalCount - finalMovies.length;

      if (missingCount > 0 && options.genreIds.isNotEmpty) {
        final otherData = await supabase
            .from('movies')
            .select()
            .not('genre_ids', 'ov',
                options.genreIds)
            .order('popularity', ascending: false)
            .limit(missingCount + 10); 

        final otherMovies =
            (otherData as List).map((json) => Movie.fromJson(json)).toList();

        for (var movie in otherMovies) {
          if (finalMovies.length >= totalCount) break;
          if (!finalMovies.any((m) => m.id == movie.id)) {
            finalMovies.add(movie);
          }
        }
      }

      // Fallback jakby nie było tylu filmów spoza wybranych gatunków
      missingCount = totalCount - finalMovies.length;

      if (missingCount > 0) {
        final fallbackData = await supabase
            .from('movies')
            .select()
            .order('popularity', ascending: false)
            .limit(totalCount +
                20); 

        final fallbackMovies =
            (fallbackData as List).map((json) => Movie.fromJson(json)).toList();

        for (var movie in fallbackMovies) {
          if (finalMovies.length >= totalCount) break;

          if (!finalMovies.any((m) => m.id == movie.id)) {
            finalMovies.add(movie);
          }
        }
      }

      finalMovies.shuffle();

      state = finalMovies;
    } catch (error) {
      print('Error loading recommendation movies: $error');
      state = [];
    }
  }
}

final moviesProvider = NotifierProvider<MoviesNotifier, List<Movie>>(
  MoviesNotifier.new,
);

final genresProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase
      .from('genres')
      .select('id, name, movie_count')
      .gt('movie_count', 0)
      .order('movie_count', ascending: false)
      .limit(20);
  return List<Map<String, dynamic>>.from(data);
});
