import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class WatchlistNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    _loadWatchlist();
    return {};
  }

  Future<void> _loadWatchlist() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('watchlist')
          .select('movie_id')
          .eq('user_id', userId);

      final movieIds = (data as List)
          .map((item) => item['movie_id'] as int)
          .toSet();

      state = movieIds;
    } catch (error) {
      print('Error loading watchlist: $error');
      state = {};
    }
  }

  Future<void> toggleMovie(int movieId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final isInWatchlist = state.contains(movieId);

    if (isInWatchlist) {
      state = {...state}..remove(movieId);
    } else {
      state = {...state, movieId};
    }

    try {
      if (isInWatchlist) {
        await supabase
            .from('watchlist')
            .delete()
            .eq('user_id', userId)
            .eq('movie_id', movieId);
      } else {
        await supabase.from('watchlist').insert({
          'user_id': userId,
          'movie_id': movieId,
        });
      }
    } catch (error) {
      if (isInWatchlist) {
        state = {...state, movieId};
      } else {
        state = {...state}..remove(movieId);
      }
    }
  }

  bool isInWatchlist(int movieId) {
    return state.contains(movieId);
  }
}

final watchlistProvider = NotifierProvider<WatchlistNotifier, Set<int>>(
  WatchlistNotifier.new,
);