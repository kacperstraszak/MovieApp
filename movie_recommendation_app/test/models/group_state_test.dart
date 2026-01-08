import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/models/group.dart';
import 'package:movie_recommendation_app/models/group_state.dart';

void main() {
  group('GroupState', () {
    test('copyWith updates specific fields and keeps others', () {
      const state = GroupState(isLoading: true);
      
      final newState = state.copyWith(errorMessage: 'Initial Error');

      expect(newState.isLoading, isTrue);
      expect(newState.errorMessage, 'Initial Error');
      expect(newState.members, isEmpty);
    });

    test('copyWith allows setting nullable fields to null if supported by logic', () {
      const state = GroupState(errorMessage: 'Some Error');
      
      final newState = state.copyWith(errorMessage: null);
      
      expect(newState.errorMessage, isNull);
    });

    test('copyWith does not overwrite currentGroup if parameter is null', () {
      final group = const Group(
        id: '1', 
        code: 'A', 
        adminId: 'admin', 
        isActive: true
      );
      final state = GroupState(currentGroup: group);

      final newState = state.copyWith(isLoading: true);

      expect(newState.currentGroup, equals(group));
    });
  });
}