import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/providers/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:movie_recommendation_app/providers/auth_provider.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<PostgrestList> {}

class MockUser extends Mock implements User {}

class FakePostgrestTransformBuilder extends Fake implements PostgrestTransformBuilder<PostgrestMap> {
  final Map<String, dynamic> _data;

  FakePostgrestTransformBuilder(this._data);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestMap value) onValue, {
    Function? onError,
  }) {
    return Future.value(_data).then(onValue, onError: onError);
  }
}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder mockFilterBuilder;
  late ProviderContainer container;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);

    container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier Tests', () {
    test('Stan początkowy powinien być pusty', () {
      final state = container.read(authProvider);
      expect(state.user, isNull);
      expect(state.profile, isNull);
      expect(state.isAuthenticating, isFalse);
    });

    test('SignIn sukces - powinien zaktualizować stan użytkownika i profilu', () async {
      const email = 'test@example.com';
      const password = 'password123';
      
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockUser.email).thenReturn(email);

      final authResponse = AuthResponse(session: null, user: mockUser);

      when(() => mockAuth.signInWithPassword(email: email, password: password))
          .thenAnswer((_) async => authResponse);

      when(() => mockSupabase.from(kProfilesTable)).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.select(any())).thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any())).thenAnswer((_) => mockFilterBuilder);
      
      when(() => mockFilterBuilder.single()).thenAnswer(
        (_) => FakePostgrestTransformBuilder({
          'username': 'TestUser',
          'image_url': 'http://avatar.com',
        }),
      );

      final notifier = container.read(authProvider.notifier);
      await notifier.signIn(email: email, password: password);

      final state = container.read(authProvider);
      
      expect(state.user, isNotNull);
      expect(state.user!.email, email);
      expect(state.profile, isNotNull);
      expect(state.profile!.username, 'TestUser');
      expect(state.errorMessage, isNull);
    });

    test('SignIn błąd - powinien ustawić errorMessage', () async {
      const email = 'wrong@email.com';
      const password = 'badpass';

      when(() => mockAuth.signInWithPassword(email: email, password: password))
          .thenThrow(const AuthException('Invalid login credentials'));

      final notifier = container.read(authProvider.notifier);
      await notifier.signIn(email: email, password: password);

      final state = container.read(authProvider);
      
      expect(state.user, isNull);
      expect(state.errorMessage, contains('Invalid login credentials'));
    });

    test('SignOut - powinien wyczyścić stan', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      
      final notifier = container.read(authProvider.notifier);
      await notifier.signOut();
      
      final state = container.read(authProvider);
      expect(state.user, isNull);
      expect(state.profile, isNull);
    });
  });
}