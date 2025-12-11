import 'package:movie_recommendation_app/models/movie.dart';

class ResultMovie {
  ResultMovie({
    required this.movie,
    required this.score,
  });
  
  final Movie movie;
  final double score;
}
