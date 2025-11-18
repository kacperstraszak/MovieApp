import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class MoviesNotifier extends Notifier<List<Movie>> {
  @override
  List<Movie> build() {
    loadMovies();
    return [];
  }

  Future<void> loadMovies() async {
    try {
      final data = await supabase
          .from('movies')
          .select()
          .order('release', ascending: false);

      final movies =
          (data as List).map((json) => Movie.fromJson(json)).toList();

      state = movies;
    } catch (error) {
      state = [];
    }
  }

  Future<void> refresh() async {
    await loadMovies();
  }
}

final moviesProvider = NotifierProvider<MoviesNotifier, List<Movie>>(
  MoviesNotifier.new,
);
