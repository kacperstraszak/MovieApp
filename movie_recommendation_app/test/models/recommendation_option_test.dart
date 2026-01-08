import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/models/recommendation_option.dart';

void main() {
  group('RecommendationOption', () {
    test('Default constructor sets correct default values', () {
      const options = RecommendationOption();

      expect(options.includeCrew, isFalse);
      expect(options.movieCount, 20);
      expect(options.genreIds, isEmpty);
    });

    test('Custom values are preserved', () {
      const options = RecommendationOption(
        includeCrew: true,
        movieCount: 50,
        genreIds: [12, 14],
      );

      expect(options.includeCrew, isTrue);
      expect(options.movieCount, 50);
      expect(options.genreIds, contains(12));
    });
  });
}