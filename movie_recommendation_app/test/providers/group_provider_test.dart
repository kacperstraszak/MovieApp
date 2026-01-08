import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movie_recommendation_app/providers/group_provider.dart';
import 'package:movie_recommendation_app/providers/supabase_client_provider.dart';
import 'package:movie_recommendation_app/models/group.dart';
import 'package:movie_recommendation_app/models/group_state.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgresFilterBuilder extends Mock implements PostgrestFilterBuilder {}

class MockPostgresTransformBuilder extends Mock implements PostgrestTransformBuilder {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late ProviderContainer container;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-123');

    when(() => mockSupabase.channel(any()))
        .thenThrow(Exception('Realtime disabled in unit tests'));

    container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state is empty GroupState', () {
    final state = container.read(groupProvider);
    expect(state, const GroupState());
  });

  test('createGroup sets error when user is null', () async {
    when(() => mockAuth.currentUser).thenReturn(null);

    final notifier = container.read(groupProvider.notifier);
    final result = await notifier.createGroup();

    expect(result, isNull);
    expect(
      container.read(groupProvider).errorMessage,
      contains('User not authenticated'),
    );
  });

  test('createGroup handles Supabase exception gracefully', () async {
    when(() => mockSupabase.from(any())).thenThrow(Exception('DB error'));

    final notifier = container.read(groupProvider.notifier);
    final result = await notifier.createGroup();

    expect(result, isNull);
    expect(
      container.read(groupProvider).errorMessage,
      contains('Failed to create group'),
    );
  });

  test('joinGroup handles Supabase error', () async {
    when(() => mockSupabase.from(any())).thenThrow(Exception('DB error'));

    final notifier = container.read(groupProvider.notifier);
    final result = await notifier.joinGroup('CODE');

    expect(result, isNull);
    expect(
      container.read(groupProvider).errorMessage,
      contains('Failed to join group'),
    );
  });

  test('isCurrentUserAdmin returns true for admin', () {
    final notifier = container.read(groupProvider.notifier);

    notifier.state = notifier.state.copyWith(
      currentGroup: const Group(
        id: 'group-1',
        code: 'CODE',
        adminId: 'user-123',
        status: 'lobby',
        isActive: true,
      ),
    );

    expect(notifier.isCurrentUserAdmin(), true);
  });

  test('isCurrentUserAdmin returns false for non-admin', () {
    final notifier = container.read(groupProvider.notifier);

    notifier.state = notifier.state.copyWith(
      currentGroup: const Group(
        id: 'group-1',
        code: 'CODE',
        adminId: 'other-user',
        status: 'lobby',
        isActive: true,
      ),
    );

    expect(notifier.isCurrentUserAdmin(), false);
  });

  test('isCurrentUserAdmin returns false when no group', () {
    final notifier = container.read(groupProvider.notifier);

    notifier.state = notifier.state.copyWith(currentGroup: null);

    expect(notifier.isCurrentUserAdmin(), false);
  });

  test('isCurrentUserAdmin returns false when user is null', () {
    when(() => mockAuth.currentUser).thenReturn(null);

    final notifier = container.read(groupProvider.notifier);

    notifier.state = notifier.state.copyWith(
      currentGroup: const Group(
        id: 'group-1',
        code: 'CODE',
        adminId: 'user-123',
        status: 'lobby',
        isActive: true,
      ),
    );

    expect(notifier.isCurrentUserAdmin(), false);
  });

  test('leaveGroup handles when no group exists', () async {
    final notifier = container.read(groupProvider.notifier);

    notifier.state = notifier.state.copyWith(currentGroup: null);

    await notifier.leaveGroup();

    expect(container.read(groupProvider), const GroupState());
  });

  test('updateCurrentUserStatus sets error when user is null', () async {
    when(() => mockAuth.currentUser).thenReturn(null);

    final notifier = container.read(groupProvider.notifier);

    await notifier.updateCurrentUserStatus(
      isFinished: true,
      action: 'vote',
    );

    expect(
      container.read(groupProvider).errorMessage,
      contains('User not authenticated'),
    );
  });

  test('updateCurrentUserStatus handles Supabase error', () async {
    when(() => mockSupabase.from(any())).thenThrow(Exception('DB error'));

    final notifier = container.read(groupProvider.notifier);

    notifier.state = notifier.state.copyWith(
      currentGroup: const Group(
        id: 'group-1',
        code: 'CODE',
        adminId: 'user-123',
        status: 'lobby',
        isActive: true,
      ),
    );

    await notifier.updateCurrentUserStatus(
      isFinished: true,
      action: 'vote',
    );

    expect(
      container.read(groupProvider).errorMessage,
      contains('Failed to update user status'),
    );
  });

  test('updateCurrentUserStatus sets error when no group', () async {
    final notifier = container.read(groupProvider.notifier);

    notifier.state = notifier.state.copyWith(currentGroup: null);

    await notifier.updateCurrentUserStatus(
      isFinished: true,
      action: 'vote',
    );

    expect(
      container.read(groupProvider).errorMessage,
      contains('No active group'),
    );
  });
}