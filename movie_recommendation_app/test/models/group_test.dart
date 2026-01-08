import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/models/group.dart';

void main() {
  group('Group', () {
    test('fromJson assigns default status if missing', () {
      final json = {
        'id': 'g1',
        'code': '123456',
        'admin_id': 'admin',
        'is_active': true,
        'status': null,
      };

      final group = Group.fromJson(json);

      expect(group.status, 'lobby');
    });

    test('toJson produces correct map keys', () {
      const group = Group(
        id: 'g2',
        code: 'CODE',
        adminId: 'admin2',
        isActive: false,
        status: 'swipe',
      );

      final json = group.toJson();

      expect(json['lobby'], 'swipe'); 
      expect(json['is_active'], false);
    });
  });
}