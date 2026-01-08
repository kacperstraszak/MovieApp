import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/models/movie.dart';

void main() {
  group('Movie', () {
    test('fromJson handles standard data correctly', () {
      final json = {
        'id': 101,
        'title': 'Test Movie',
        'description': 'Description',
        'poster_path': '/poster.jpg',
        'backdrop_path': '/backdrop.jpg',
        'release': '2023-01-01',
      };

      final movie = Movie.fromJson(json);

      expect(movie.id, 101);
      expect(movie.title, 'Test Movie');
      expect(movie.backdropPath, '/backdrop.jpg');
    });

    test('fromJson handles null optional fields by assigning defaults', () {
      final json = {
        'id': 102,
        'title': 'Null Fields Movie',
        'description': null,
        'poster_path': null,
        'backdrop_path': null,
        'release': null,
      };

      final movie = Movie.fromJson(json);

      expect(movie.description, isEmpty);
      expect(movie.posterPath, isEmpty);
      expect(movie.backdropPath, isNull);
      expect(movie.releaseDate, 'Unknown');
    });

    test('fromJson throws error if required fields are missing', () {
      final json = {
        'title': 'Missing ID',
      };

      expect(() => Movie.fromJson(json), throwsA(anything));
    });
  });
}