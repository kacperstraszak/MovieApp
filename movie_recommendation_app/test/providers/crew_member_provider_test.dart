import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:movie_recommendation_app/providers/crew_member_provider.dart';
import 'package:movie_recommendation_app/providers/supabase_client_provider.dart';
import 'package:movie_recommendation_app/models/crew_member.dart';
import 'package:movie_recommendation_app/models/movie.dart';

class FakeSupabaseClient implements SupabaseClient {
  FakeSupabaseClient(Map<String, List<Map<String, dynamic>>> responses)
      : responses = responses.map((key, value) => MapEntry(
            key,
            value.map((item) => Map<String, dynamic>.from(item)).toList()));

  final Map<String, List<Map<String, dynamic>>> responses;

  @override
  SupabaseQueryBuilder from(String table) {
    return FakeQueryBuilder(responses[table] ?? []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQueryBuilder implements SupabaseQueryBuilder {
  FakeQueryBuilder(this.response);

  final List<Map<String, dynamic>> response;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return FakePostgrestListBuilder(response);
  }

  @override
  PostgrestFilterBuilder<PostgrestList> insert(Object values, {bool defaultToNull = true}) {
    return FakePostgrestListBuilder(response);
  }

  @override
  PostgrestFilterBuilder<PostgrestList> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    return FakePostgrestListBuilder(response);
  }
  
  @override
  PostgrestFilterBuilder<PostgrestList> delete() {
    return FakePostgrestListBuilder(response);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePostgrestListBuilder
    implements
        PostgrestFilterBuilder<PostgrestList>,
        PostgrestTransformBuilder<PostgrestList> {
  FakePostgrestListBuilder(this.response);

  final List<Map<String, dynamic>> response;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    final mutableList = List<Map<String, dynamic>>.from(response);
    return Future<PostgrestList>.value(mutableList).then(onValue, onError: onError);
  }

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<PostgrestList> in_(String column, List<Object> values) => this;

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = true,
    bool nullsFirst = false,
    String? referencedTable,
  }) => this;

  @override
  PostgrestTransformBuilder<PostgrestList> limit(int count, {String? referencedTable}) => this;

  @override
  PostgrestTransformBuilder<PostgrestList> range(int from, int to, {String? referencedTable}) => this;

  @override
  PostgrestTransformBuilder<PostgrestMap> single() {
    if (response.isEmpty) throw const PostgrestException(message: 'Row not found');
    return FakePostgrestMapBuilder(response.first);
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    if (response.isEmpty) return FakePostgrestNullableMapBuilder(null);
    return FakePostgrestNullableMapBuilder(response.first);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #then) return super.noSuchMethod(invocation);
    return this;
  }
}

class FakePostgrestMapBuilder implements PostgrestTransformBuilder<PostgrestMap> {
  FakePostgrestMapBuilder(this.data);
  final PostgrestMap data;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestMap value) onValue, {
    Function? onError,
  }) {
    return Future.value(data).then(onValue, onError: onError);
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}

class FakePostgrestNullableMapBuilder implements PostgrestTransformBuilder<PostgrestMap?> {
  FakePostgrestNullableMapBuilder(this.data);
  final PostgrestMap? data;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) {
    return Future.value(data).then(onValue, onError: onError);
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => this;
}

final mockCrewMember1 = CrewMember(
  id: 1,
  name: 'John Doe',
  profilePath: '/path1.jpg',
  popularity: 10,
  department: 'Acting',
);

final mockCrewMember2 = CrewMember(
  id: 2,
  name: 'Jane Smith',
  profilePath: '/path2.jpg',
  popularity: 9,
  department: 'Directing',
);

void main() {
  late ProviderContainer container;

  tearDown(() {
    container.dispose();
  });

  group('PopularPeopleProvider', () {
    test('initial state empty', () {
      container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(FakeSupabaseClient({})),
        ],
      );
      expect(container.read(popularPeopleProvider), isEmpty);
    });

    test('loadPopularPeople loads people', () async {
      container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(
            FakeSupabaseClient({
              'people': [
                {
                  'id': 1,
                  'name': 'John Doe',
                  'profile_path': '/path1.jpg',
                  'popularity': 10,
                  'known_for_department': 'Acting',
                },
                {
                  'id': 2,
                  'name': 'Jane Smith',
                  'profile_path': '/path2.jpg',
                  'popularity': 9,
                  'known_for_department': 'Directing',
                },
              ],
            }),
          ),
        ],
      );

      await container.read(popularPeopleProvider.notifier).loadPopularPeople();

      final state = container.read(popularPeopleProvider);
      
      expect(state.length, 2);
      expect(state.first, isA<CrewMember>());
    });

    test('recordInteraction removes liked person', () async {
      container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(
            FakeSupabaseClient({'liked_people': []}),
          ),
        ],
      );

      final notifier = container.read(popularPeopleProvider.notifier);
      notifier.state = [mockCrewMember1, mockCrewMember2];

      await notifier.recordInteraction(
        groupId: 'g',
        crew: mockCrewMember1,
        liked: true,
      );

      expect(container.read(popularPeopleProvider).length, 1);
    });
  });

  group('PersonMoviesProvider', () {
    test('loadMoviesForPerson loads movies', () async {
      container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(
            FakeSupabaseClient({
              'movie_people': [
                {
                  'movies': {
                    'id': 101,
                    'title': 'Movie 1',
                    'description': 'Desc',
                    'release': '2024-01-01',
                    'poster_path': '/p.jpg',
                    'backdrop_path': '/b.jpg',
                    'popularity': 10.0,
                    'vote_average': 7.0,
                    'vote_count': 100,
                  }
                },
                {
                  'movies': {
                    'id': 102,
                    'title': 'Movie 2',
                    'description': 'Desc',
                    'release': '2024-02-01',
                    'poster_path': '/p2.jpg',
                    'backdrop_path': '/b2.jpg',
                    'popularity': 10.0,
                    'vote_average': 7.0,
                    'vote_count': 100,
                  }
                },
              ],
            }),
          ),
        ],
      );

      await container.read(personMoviesProvider.notifier).loadMoviesForPerson(1);

      final state = container.read(personMoviesProvider);
      expect(state.length, 2);
      expect(state.first, isA<Movie>());
    });

    test('loadMoviesForPerson removes duplicates', () async {
      container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(
            FakeSupabaseClient({
              'movie_people': [
                {
                  'movies': {
                    'id': 101,
                    'title': 'Movie',
                    'description': 'Desc',
                    'release': '2024-01-01',
                    'poster_path': '/p.jpg',
                    'backdrop_path': '/b.jpg',
                    'popularity': 10.0,
                    'vote_average': 7.0,
                    'vote_count': 100,
                  }
                },
                {
                  'movies': {
                    'id': 101,
                    'title': 'Movie',
                    'description': 'Desc',
                    'release': '2024-01-01',
                    'poster_path': '/p.jpg',
                    'backdrop_path': '/b.jpg',
                    'popularity': 10.0,
                    'vote_average': 7.0,
                    'vote_count': 100,
                  }
                },
              ],
            }),
          ),
        ],
      );

      await container.read(personMoviesProvider.notifier).loadMoviesForPerson(1);

      expect(container.read(personMoviesProvider).length, 1);
    });

    test('loadMoviesForPerson ignores null movies', () async {
      container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(
            FakeSupabaseClient({
              'movie_people': [
                {'movies': null},
                {
                  'movies': {
                    'id': 102,
                    'title': 'Valid',
                    'description': 'Desc',
                    'release': '2024-02-01',
                    'poster_path': '/p.jpg',
                    'backdrop_path': '/b.jpg',
                    'popularity': 10.0,
                    'vote_average': 7.0,
                    'vote_count': 100,
                  }
                },
              ],
            }),
          ),
        ],
      );

      await container.read(personMoviesProvider.notifier).loadMoviesForPerson(1);

      expect(container.read(personMoviesProvider).length, 1);
    });
  });
}