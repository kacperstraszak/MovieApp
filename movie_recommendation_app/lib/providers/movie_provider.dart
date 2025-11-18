import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class MoviesNotifier extends Notifier<List<Movie>> {
  @override
  List<Movie> build() {
    loadPlaces();
    return const [];
  }
}

Future<void> loadPlaces() async {
  try {
    final data = await supabase
        .from('movies')
        .select()
        .order('release', ascending: false)
        .withConverter<List<Movie>>(
            (data) => data.map(Movie.fromJson).toList());
  } catch (error) {}
}

final placesProvider = NotifierProvider<MoviesNotifier, List<Movie>>(MoviesNotifier.new);
