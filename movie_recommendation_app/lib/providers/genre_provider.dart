import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

final genresProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase
      .from('genres')
      .select('id, name, movie_count')
      .gt('movie_count', 0)
      .order('movie_count', ascending: false)
      .limit(20);

  return List<Map<String, dynamic>>.from(data);
});
