import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/models/result_movie.dart';
import 'package:movie_recommendation_app/providers/group_provider.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class ResultNotifier extends Notifier<List<ResultMovie>> {
  @override
  List<ResultMovie> build() {
    return [];
  }

  Future<void> loadResults() async {
    final groupId = ref.read(groupProvider).currentGroup?.id;

    if (groupId == null) {
      state = [];
      return;
    }

    try {
      final List<dynamic> statsData = await supabase.rpc(
        'get_group_results',
        params: {'target_group_id': groupId},
      );

      if (statsData.isEmpty) {
        state = [];
        return;
      }

      final movieIds = statsData.map((e) => e['movie_id'] as int).toList();

      final moviesData =
          await supabase.from('movies').select().inFilter('id', movieIds);

      final movies =
          (moviesData as List).map((json) => Movie.fromJson(json)).toList();

      final List<ResultMovie> results = [];

      for (final stat in statsData) {
        final movie = movies.firstWhere(
          (m) => m.id == stat['movie_id'],
        );

        if (movie.id != 0) {
          results.add(ResultMovie(
            movie: movie,
            score: (stat['consensus_score'] as num?)?.toDouble() ?? 0.0,
          ));
        }
      }

      state = results;
    } catch (e) {
      state = [];
    }
  }
}

final resultsProvider = NotifierProvider<ResultNotifier, List<ResultMovie>>(
  ResultNotifier.new,
);
