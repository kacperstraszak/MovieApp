import 'package:flutter_test/flutter_test.dart';
import 'package:movie_recommendation_app/models/group_member.dart';

void main() {
  group('GroupMember', () {
    test('fromPresence parses valid joined_at date string', () {
      final json = {
        'user_id': 'u1',
        'username': 'User',
        'image_url': 'url',
        'is_admin': true,
        'joined_at': '2023-12-25T10:00:00.000Z',
      };

      final member = GroupMember.fromPresence(json);
      expect(member.joinedAt?.year, 2023);
      expect(member.joinedAt?.month, 12);
    });

    test('fromPresence defaults to now if joined_at is missing', () {
      final json = {
        'user_id': 'u2',
        'username': 'User',
        'image_url': 'url',
        'is_admin': false,
        'joined_at': null,
      };

      final member = GroupMember.fromPresence(json);
      expect(member.joinedAt, isNotNull);
      expect(
          member.joinedAt!.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
    });

    test('fromPresence handles invalid date string format gracefully', () {
      final json = {
        'user_id': 'u3',
        'username': 'User',
        'image_url': 'url',
        'is_admin': false,
        'joined_at': 'invalid-date-format',
      };

      final member = GroupMember.fromPresence(json);
      expect(member.joinedAt, isNull);
    });

    test('toPresencePayload generates correct map structure', () {
      final member = const GroupMember(
        userId: 'u4',
        username: 'TestUser',
        imageUrl: 'img.png',
        isAdmin: true,
      );

      final payload = member.toPresencePayload();

      expect(payload['user_id'], 'u4');
      expect(payload['is_admin'], true);
      expect(payload['joined_at'], isA<String>());
    });
  });
}