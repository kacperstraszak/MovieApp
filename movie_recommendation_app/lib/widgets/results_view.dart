import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/providers/result_provider.dart';
import 'package:movie_recommendation_app/widgets/movie_element.dart';
import 'package:movie_recommendation_app/widgets/rank_badge.dart';

class ResultsView extends ConsumerWidget {
  const ResultsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(resultsProvider);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Getting the Results...',
              style: TextStyle(
                  fontSize: 18, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'First Pick',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
          ),
        ),
        const SizedBox(height: 16),
        RankBadge(
          rank: 1,
          consensusScore: results[0].score,
        ),
        const SizedBox(height: 8),
        MovieElement(movie: results[0].movie),
        const SizedBox(height: 32),
        Text(
          'Alternative Picks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
          ),
        ),
        const SizedBox(height: 16),
        RankBadge(
          rank: 2,
          consensusScore: results[1].score,
        ),
        const SizedBox(height: 8),
        MovieElement(movie: results[1].movie),
        const SizedBox(height: 16),
        RankBadge(
          rank: 3,
          consensusScore: results[2].score,
        ),
        const SizedBox(height: 8),
        MovieElement(movie: results[2].movie),
        const SizedBox(height: 12),
        Text(
          'The results were determined based on the votes of all group members.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
