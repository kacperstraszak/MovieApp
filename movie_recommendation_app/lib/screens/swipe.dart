import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/models/crew_member.dart';
import 'package:movie_recommendation_app/providers/group_provider.dart';
import 'package:movie_recommendation_app/providers/movie_provider.dart';
import 'package:movie_recommendation_app/providers/crew_member_provider.dart';
import 'package:movie_recommendation_app/providers/recommendation_provider.dart';
import 'package:movie_recommendation_app/screens/recommendations.dart';
import 'package:movie_recommendation_app/widgets/action_button.dart';
import 'package:movie_recommendation_app/widgets/rating_dialog.dart';
import 'package:movie_recommendation_app/widgets/swipe_crew_member.dart';
import 'package:movie_recommendation_app/widgets/swipe_movie_element.dart';

enum SwipeMode { movies, crew }

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key, required this.swipeCrew});
  final bool swipeCrew;

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  double _dragOffset = 0;
  bool _isDragging = false;
  SwipeMode _currentMode = SwipeMode.movies;

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

  void _handleMovieSwipe(BuildContext context, Movie movie, bool liked) async {
    if (!liked) {
      await ref.read(recommendationMoviesProvider.notifier).recordInteraction(
            movieId: movie.id,
            type: 'dislike',
            rating: 0.5,
          );
    } else {
      final double? stars = await showDialog<double>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const RatingDialog(),
      );

      if (stars == null) {
        setState(() {
          _dragOffset = 0;
          _isDragging = false;
        });
        return;
      }

      await ref.read(recommendationMoviesProvider.notifier).recordInteraction(
            movieId: movie.id,
            type: 'like',
            rating: stars,
          );
    }

    setState(() {
      _dragOffset = 0;
      _isDragging = false;
    });
  }

  void _handleNotSeen(BuildContext context, int movieId) async {
    await ref.read(recommendationMoviesProvider.notifier).recordInteraction(
          movieId: movieId,
          type: 'not_seen',
        );

    setState(() {
      _dragOffset = 0;
      _isDragging = false;
    });
  }

  void _handleCrewSwipe(
    BuildContext context,
    CrewMember crew,
    bool liked,
  ) async {
    final groupId = ref.read(groupProvider).currentGroup?.id;
    if (groupId == null) return;

    await ref.read(popularPeopleProvider.notifier).recordInteraction(
          groupId: groupId,
          crew: crew,
          liked: liked,
        );

    setState(() {
      _dragOffset = 0;
      _isDragging = false;
    });
  }

  void _checkAndSwitchMode(
    List<Movie> movies,
    List<CrewMember> crew,
  ) {
    if (_currentMode == SwipeMode.movies &&
        movies.isEmpty &&
        widget.swipeCrew &&
        crew.isNotEmpty) {
      setState(() => _currentMode = SwipeMode.crew);
    }
  }

  Future<void> _finishedSwiping(BuildContext context) async {
    await ref
        .read(groupProvider.notifier)
        .updateCurrentUserStatus(isFinished: true, action: 'swipe');
  }

  void _pushNextScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
      );
    }
  }

  void _finishPhase(BuildContext context) async {
    final provider = ref.read(groupRecommendationsProvider.notifier);
    final success = await provider.generateRecommendations();
    if (success) {
      await provider.loadGroupRecommendations();
    }
    _pushNextScreen();
  }

  @override
  Widget build(BuildContext context) {
    final movies = ref.watch(recommendationMoviesProvider);
    final crew =
        widget.swipeCrew ? ref.watch(popularPeopleProvider) : <CrewMember>[];
    final screenWidth = MediaQuery.of(context).size.width;

    ref.listen(groupProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage!.contains('closed by admin')) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          _showSnackbar(
              next.errorMessage!, Theme.of(context).colorScheme.error);
          Navigator.of(context).pop();
        }
      }

      if (previous?.currentGroup?.status != next.currentGroup?.status &&
          next.currentGroup?.status == 'swiped') {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          _showSnackbar(
            'Everyone finished! Wait for Recommendations!',
            Colors.green,
          );
          _finishPhase(context);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndSwitchMode(movies, crew);
    });

    final isFinished = movies.isEmpty && (!widget.swipeCrew || crew.isEmpty);

    if (isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finishedSwiping(context);
      });
    }

    final showContent =
        (_currentMode == SwipeMode.movies && movies.isNotEmpty) ||
            (_currentMode == SwipeMode.crew && crew.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentMode == SwipeMode.movies
              ? 'Rate Movies (${movies.length})'
              : 'Rate Crew (${crew.length})',
        ),
        automaticallyImplyLeading: false,
      ),
      body: !showContent
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 80, color: Colors.green),
                  const SizedBox(height: 20),
                  Text(
                    'Waiting for Everyone to finish...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                if (_isDragging)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: AnimatedOpacity(
                        opacity: (_dragOffset.abs() / 100).clamp(0.0, 1.0),
                        duration: const Duration(milliseconds: 50),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _dragOffset > 0
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.red.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              _dragOffset > 0 ? Icons.favorite : Icons.close,
                              size: 100,
                              color: _dragOffset > 0
                                  ? Colors.green.withValues(alpha: 0.8)
                                  : Colors.red.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onHorizontalDragStart: (_) =>
                            setState(() => _isDragging = true),
                        onHorizontalDragUpdate: (details) =>
                            setState(() => _dragOffset += details.delta.dx),
                        onHorizontalDragEnd: (_) {
                          if (_dragOffset.abs() > screenWidth * 0.3) {
                            final liked = _dragOffset > 0;

                            if (_currentMode == SwipeMode.movies) {
                              _handleMovieSwipe(context, movies.first, liked);
                            } else {
                              _handleCrewSwipe(context, crew.first, liked);
                            }
                          } else {
                            setState(() {
                              _dragOffset = 0;
                              _isDragging = false;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: _isDragging
                              ? Duration.zero
                              : const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          transform:
                              Matrix4.translationValues(_dragOffset, 0, 0)
                                ..rotateZ(_dragOffset * 0.0005),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _currentMode == SwipeMode.movies
                                ? SwipeMovieElement(movie: movies.first)
                                : SwipeCrewMemberElement(
                                    crewMember: crew.first,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: _currentMode == SwipeMode.movies
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ActionButton(
                                  onPressed: () => _handleMovieSwipe(
                                      context, movies.first, false),
                                  icon: Icons.close,
                                  color: Colors.red,
                                  size: 75,
                                ),
                                ActionButton(
                                  onPressed: () =>
                                      _handleNotSeen(context, movies.first.id),
                                  icon: Icons.visibility_off,
                                  color: Colors.grey,
                                  size: 54,
                                  label: 'Not Seen',
                                ),
                                ActionButton(
                                  onPressed: () => _handleMovieSwipe(
                                      context, movies.first, true),
                                  icon: Icons.favorite,
                                  color: Colors.green,
                                  size: 75,
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ActionButton(
                                  onPressed: () => _handleCrewSwipe(
                                      context, crew.first, false),
                                  icon: Icons.close,
                                  color: Colors.red,
                                  size: 75,
                                ),
                                const SizedBox(width: 40),
                                ActionButton(
                                  onPressed: () => _handleCrewSwipe(
                                      context, crew.first, true),
                                  icon: Icons.favorite,
                                  color: Colors.green,
                                  size: 75,
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
    );
  }
}
