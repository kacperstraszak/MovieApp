import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/providers/group_provider.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class GroupRecommendationsNotifier extends Notifier<List<Movie>> {
  @override
  List<Movie> build() {
    return [];
  }

  Future<bool> generateRecommendations() async {
    final groupId = ref.read(groupProvider).currentGroup?.id;
    if (groupId == null) return false;

    try {
      final response = await supabase.functions.invoke(
        'generate-recommendations',
        body: {'groupId': groupId},
      );

      final success = response.data['success'] == true;
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadGroupRecommendations() async {
    state = [];
    final groupId = ref.read(groupProvider).currentGroup?.id;
    if (groupId == null) {
      state = [];
      return;
    }

    try {
      final data = await supabase
          .from('group_recommendations')
          .select('movie_id, position')
          .eq('group_id', groupId)
          .order('position', ascending: true);

      if (data.isEmpty) {
        state = [];
        return;
      }

      final movieIds = data.map((e) => e['movie_id'] as int).toList();

      final moviesData =
          await supabase.from('movies').select().inFilter('id', movieIds);

      final movies =
          (moviesData as List).map((json) => Movie.fromJson(json)).toList();

      movies.sort((a, b) {
        final posA = data.firstWhere((e) => e['movie_id'] == a.id)['position'];
        final posB = data.firstWhere((e) => e['movie_id'] == b.id)['position'];
        return posA - posB;
      });

      state = movies;
    } catch (e) {
      state = [];
    }
  }

  Future<void> voteForMovies({
    required Map<int, double> userRatings,
  }) async {
    final groupId = ref.read(groupProvider).currentGroup?.id;
    final userId = supabase.auth.currentUser?.id;

    if (groupId == null || userId == null) return;

    try {
      userRatings.forEach((movieId, rating) async {
        final recommendation = await supabase
            .from('group_recommendations')
            .select('id')
            .eq('group_id', groupId)
            .eq('movie_id', movieId)
            .single();

        final recId = recommendation['id'];

        await supabase.from('recommendation_votes').upsert(
          {
            'recommendation_id': recId,
            'user_id': userId,
            'rating': rating.toInt(),
          },
          onConflict: 'recommendation_id, user_id',
        );
      });
    } catch (e) {
      print("Error voting: $e");
    }
  }
}

final groupRecommendationsProvider =
    NotifierProvider<GroupRecommendationsNotifier, List<Movie>>(
  GroupRecommendationsNotifier.new,
);
