import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/crew_member.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class PopularPeopleNotifier extends Notifier<List<CrewMember>> {
  @override
  List<CrewMember> build() {
    return [];
  }

  Future<void> loadPopularPeople() async {
    try {
      final data = await supabase
          .from('people')
          .select()
          .order('popularity', ascending: false)
          .limit(20);

      final allPeople =
          (data as List).map((json) => CrewMember.fromJson(json)).toList();

      allPeople.shuffle(Random());

      state = allPeople.take(5).toList();
    } catch (_) {
      state = [];
    }
  }

  Future<void> recordInteraction({
    required String groupId,
    required CrewMember crew,
    required bool liked,
  }) async {
    if (liked) {
      try {
        await supabase.from('liked_people').insert({
          'group_id': groupId,
          'person_id': crew.id,
        });
      } catch (_) {}
    }

    state = state.where((c) => c.id != crew.id).toList();
  }
}

class PersonMoviesNotifier extends Notifier<List<Movie>> {
  @override
  List<Movie> build() => [];

  Future<void> loadMoviesForPerson(int personId) async {
    try {
      final data = await supabase
          .from('movie_people')
          .select('''
            role,
            character,
            job,
            movies (
              id,
              title,
              description,
              release,
              poster_path,
              backdrop_path,
              popularity,
              vote_average,
              vote_count
            )
            ''')
          .eq('person_id', personId)
          .order('movies(popularity)', ascending: false);

      final uniqueMovies = <int, Movie>{};

      for (var row in data as List) {
        final movieData = row['movies'];
        if (movieData != null) {
          final movie = Movie.fromJson(movieData);
          if (!uniqueMovies.containsKey(movie.id)) {
            uniqueMovies[movie.id] = movie;
          }
        }
      }

      final moviesList = uniqueMovies.values.toList();

      state = moviesList;
    } catch (_) {
      state = [];
    }
  }
}

final personMoviesProvider =
    NotifierProvider<PersonMoviesNotifier, List<Movie>>(
  PersonMoviesNotifier.new,
);

final popularPeopleProvider =
    NotifierProvider<PopularPeopleNotifier, List<CrewMember>>(
  PopularPeopleNotifier.new,
);
