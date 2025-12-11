import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/screens/movie_details.dart';

class RateRecommendationTile extends StatelessWidget {
  const RateRecommendationTile({
    super.key,
    required this.movie,
    required this.rating,
    required this.onRatingChanged,
  });

  final Movie movie;
  final double rating;
  final ValueChanged<double> onRatingChanged;

  @override
  Widget build(BuildContext context) {

    return Container(
      height: 170,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => MovieDetailsScreen(movie: movie),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 115,
                  height: double.infinity,
                  child: Hero(
                    tag: movie.id,
                    child: Image.network(
                      movie.posterPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.movie_outlined,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                    color: Theme.of(context).colorScheme.secondary
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  movie.releaseDate.split('-').first,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.outline,
                          )
                        ],
                      ),
                      const Spacer(),
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _getInterestLabel(rating),
                            key: ValueKey<double>(rating),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: rating > 0
                                  ? _getIconColor(rating.toInt() - 1)
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: RatingBar.builder(
                          initialRating: rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 40.0,
                          glow: false,
                          itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                          itemBuilder: (context, index) {
                            final isSelected = (index + 1) == rating.round();
                            return Icon(
                              _getIconData(index),
                              color: isSelected
                                  ? _getIconColor(index)
                                  : Theme.of(context).colorScheme.outlineVariant,
                            );
                          },
                          onRatingUpdate: (rating) {
                            onRatingChanged(rating);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInterestLabel(double rating) {
    if (rating == 0) return "HOW INTERESTED ARE YOU?";
    if (rating == 1) return "HARD PASS!";
    if (rating == 2) return "NOT REALLY";
    if (rating == 3) return "MAYBE";
    if (rating == 4) return "SOUNDS GOOD";
    if (rating == 5) return "MUST WATCH!";
    return "";
  }

  IconData _getIconData(int index) {
    switch (index) {
      case 0:
        return Icons.sentiment_very_dissatisfied_rounded;
      case 1:
        return Icons.sentiment_dissatisfied_rounded;
      case 2:
        return Icons.sentiment_neutral_rounded;
      case 3:
        return Icons.sentiment_satisfied_alt_rounded;
      case 4:
        return Icons.sentiment_very_satisfied_rounded;
      default:
        return Icons.circle;
    }
  }

  Color _getIconColor(int index) {
    switch (index) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.lightGreenAccent;
      case 4:
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }
}