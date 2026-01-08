import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/models/group_recommendation.dart';

void main() {
  group('GroupRecommendation', () {
    test('fromJson parses score when provided as double', () {
      final json = {
        'id': 'rec1',
        'group_id': 'g1',
        'movie_id': 100,
        'score': 8.5,
        'position': 1,
        'is_final': false,
      };

      final rec = GroupRecommendation.fromJson(json);
      expect(rec.score, 8.5);
    });

    test('fromJson parses score when provided as integer', () {
      final json = {
        'id': 'rec2',
        'group_id': 'g1',
        'movie_id': 100,
        'score': 10,
        'position': 2,
      };

      final rec = GroupRecommendation.fromJson(json);
      expect(rec.score, 10.0);
    });

    test('fromJson parses score when provided as String', () {
      final json = {
        'id': 'rec3',
        'group_id': 'g1',
        'movie_id': 100,
        'score': "7.9",
        'position': 3,
      };

      final rec = GroupRecommendation.fromJson(json);
      expect(rec.score, 7.9);
    });

    test('fromJson handles null optional numeric fields', () {
      final json = {
        'id': 'rec4',
        'group_id': 'g1',
        'movie_id': 100,
        'score': 5.0,
        'position': 4,
        'vote_count': null,
        'avg_rating': null,
        'consensus_score': null,
        'is_final': null,
      };

      final rec = GroupRecommendation.fromJson(json);
      expect(rec.voteCount, isNull);
      expect(rec.avgRating, isNull);
      expect(rec.consensusScore, isNull);
      expect(rec.isFinal, isFalse);
    });
  });
}