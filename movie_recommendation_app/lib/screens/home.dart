import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/providers/movie_provider.dart';
import 'package:movie_recommendation_app/screens/info.dart';
import 'package:movie_recommendation_app/utils/constants.dart';
import 'package:movie_recommendation_app/widgets/menu_drawer.dart';
import 'package:movie_recommendation_app/widgets/movie_element.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(trendingMoviesProvider);

    Widget content = preloader;
    if (movies.isNotEmpty) {
      content = ListView.builder(
        itemCount: movies.length,
        itemBuilder: (ctx, index) {
          return MovieElement(movie: movies[index]);
        },
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.outline,
      appBar: AppBar(
        title: const Text('Movie Recommendation App'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const InfoScreen(),
                ),
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: content,
    );
  }
}
