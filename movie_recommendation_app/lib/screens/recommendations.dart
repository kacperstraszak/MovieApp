import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/providers/group_provider.dart';
import 'package:movie_recommendation_app/providers/recommendation_provider.dart';
import 'package:movie_recommendation_app/screens/results.dart';
import 'package:movie_recommendation_app/widgets/rate_recommendation_tile.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _RecommendationScreenState();
  }
}

class _RecommendationScreenState extends ConsumerState<RecommendationsScreen> {
  bool _isGenerating = false;
  final Map<int, double> _userRatings = {}; // movie_id, rating

  void _showSnackbar(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleGenerateRecommendations() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final provider = ref.read(groupRecommendationsProvider.notifier);
      final success = await provider.generateRecommendations();
      if (success) {
        await provider.loadGroupRecommendations();
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(
          'Error: $e',
          Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = ref.watch(groupRecommendationsProvider);
    final isAdmin = ref.read(groupProvider.notifier).isCurrentUserAdmin();

    final ratedMoviesCount = _userRatings.length;
    final totalMovies = recommendations.length;

    void submitRatings() async {
      await ref
          .read(groupRecommendationsProvider.notifier)
          .voteForMovies(userRatings: _userRatings);
      await ref
          .read(groupProvider.notifier)
          .updateCurrentUserStatus(isFinished: true, action: 'vote');
    }

    void goToResults() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const ResultsScreen(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.outline,
      appBar: AppBar(
        title: const Text("Rate Recommendations"),
        automaticallyImplyLeading: false,
      ),
      body: recommendations.isNotEmpty
          ? Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: recommendations.length,
                    itemBuilder: (context, index) {
                      final movie = recommendations[index];
                      return RateRecommendationTile(
                        movie: movie,
                        rating: _userRatings[movie.id] ?? 0,
                        onRatingChanged: (value) {
                          setState(() {
                            _userRatings[movie.id] = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(
                      top: 16, bottom: 32, right: 24, left: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: ratedMoviesCount == totalMovies
                          ? () {
                              submitRatings();
                              goToResults();
                            }
                          : null,
                      child: Text(
                        ratedMoviesCount == totalMovies
                            ? "Submit Ratings"
                            : "Rate all to submit ($ratedMoviesCount/$totalMovies)",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAdmin) ...[
                      Text(
                        "No recommendations found yet.",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Click below to generate new suggestions for your group.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isGenerating
                            ? null
                            : _handleGenerateRecommendations,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.autorenew,
                                size: 20,
                              ),
                        label: Text(
                          _isGenerating
                              ? "Generating..."
                              : "Generate Recommendations",
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          iconColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.access_time,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Oops! Wait for data...",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No recommendations found yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isGenerating
                            ? null
                            : _handleGenerateRecommendations,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.autorenew,
                                size: 20,
                              ),
                        label: Text(
                          _isGenerating
                              ? "Generating..."
                              : "Generate Recommendations",
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          iconColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
    );
  }
}
