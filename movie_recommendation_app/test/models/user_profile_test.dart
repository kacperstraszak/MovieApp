import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('fromJson handles standard data', () {
      final json = {'username': 'TestUser', 'image_url': 'http://img.com'};
      final profile = UserProfile.fromJson(json);

      expect(profile.username, 'TestUser');
      expect(profile.imageUrl, 'http://img.com');
    });

    test('fromJson throws if required keys are missing', () {
      final json = {'username': 'TestUser'}; 
      expect(() => UserProfile.fromJson(json), throwsA(anything));
    });
  });
}