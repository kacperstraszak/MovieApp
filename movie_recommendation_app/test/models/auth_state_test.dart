import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/models/my_auth_state.dart';
import 'package:movie_recommendation_app/models/user_profile.dart';

void main() {
  group('MyAuthState', () {
    test('copyWith updates nested profile object correctly', () {
      final initialProfile = UserProfile(username: 'Old', imageUrl: 'url');
      final state = MyAuthState(profile: initialProfile, isAuthenticating: false);

      final newProfile = UserProfile(username: 'New', imageUrl: 'url');
      final newState = state.copyWith(profile: newProfile);

      expect(newState.profile!.username, 'New');
      expect(newState.isAuthenticating, false);
    });

    test('copyWith retains previous error message if not provided', () {
      const state = MyAuthState(isAuthenticating: true);
      final newState = state.copyWith(errorMessage: 'Login failed');

      expect(newState.errorMessage, 'Login failed');
      expect(newState.isAuthenticating, true);
    });
  });
}