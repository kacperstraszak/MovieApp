import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/models/crew_member.dart';

void main() {
  group('CrewMember', () {
    test('fromJson parses int popularity as double', () {
      final json = {
        'id': 1,
        'name': 'Director X',
        'profile_path': null,
        'popularity': 100,
        'known_for_department': 'Directing',
      };

      final member = CrewMember.fromJson(json);

      expect(member.popularity, 100.0);
      expect(member.popularity, isA<double>());
    });

    test('fromJson handles null popularity', () {
      final json = {
        'id': 2,
        'name': 'Actor Y',
        'profile_path': null,
        'popularity': null,
        'known_for_department': 'Acting',
      };

      final member = CrewMember.fromJson(json);

      expect(member.popularity, 0.0);
    });

    test('fromJson handles missing department key', () {
      final json = {
        'id': 3,
        'name': 'Person Z',
        'profile_path': '/path.jpg',
        'popularity': 5.5,
      };

      final member = CrewMember.fromJson(json);

      expect(member.department, isEmpty);
    });
  });
}