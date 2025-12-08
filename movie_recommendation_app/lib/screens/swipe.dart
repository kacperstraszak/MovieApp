import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/providers/movie_provider.dart';
import 'package:movie_recommendation_app/widgets/action_button.dart';
import 'package:movie_recommendation_app/widgets/star_rating_dialog.dart';
import 'package:movie_recommendation_app/widgets/swipe_movie_element.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  double _dragOffset = 0;
  bool _isDragging = false;

  void _handleSwipe(BuildContext context, Movie movie, bool liked) async {
    if (!liked) {
      await ref.read(recommendationMoviesProvider.notifier).recordInteraction(
            movieId: movie.id,
            type: 'dislike',
            rating: 1,
          );
    } else {
      final int? stars = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const StarRatingDialog(),
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

  void _finishPhase(BuildContext context) async {
    if (context.mounted) {
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (ctx) {
      //TODO: PRZEKIEROWANIE
      // }),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final movies = ref.read(recommendationMoviesProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Rate Movies (${movies.length})'),
        automaticallyImplyLeading: false,
      ),
      body: movies.isEmpty
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
                        onHorizontalDragStart: (_) {
                          setState(() => _isDragging = true);
                        },
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dragOffset += details.delta.dx;
                          });
                        },
                        onHorizontalDragEnd: (details) {
                          if (_dragOffset.abs() > screenWidth * 0.3) {
                            final liked = _dragOffset > 0;
                            _handleSwipe(context, movies.first, liked);
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
                              Matrix4.translationValues(_dragOffset, 0.0, 0.0)
                                ..rotateZ(_dragOffset * 0.0005),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SwipeMovieElement(
                              movie: movies.first,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ActionButton(
                            onPressed: () => _handleSwipe(
                              context,
                              movies.first,
                              false,
                            ),
                            icon: Icons.close,
                            color: Colors.red,
                            size: 64,
                          ),
                          ActionButton(
                            onPressed: () =>
                                _handleNotSeen(context, movies.first.id),
                            icon: Icons.visibility_off,
                            color: Colors.grey,
                            size: 50,
                            label: 'Not Seen',
                          ),
                          ActionButton(
                            onPressed: () => _handleSwipe(
                              context,
                              movies.first,
                              true,
                            ),
                            icon: Icons.favorite,
                            color: Colors.green,
                            size: 64,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
