import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/pages/details_page.dart';

class MovieElement extends StatelessWidget {
  const MovieElement({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DetailsPage(movie: movie),
            ),
          );
        },
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(movie.posterPath),
            ),
            Positioned.fill(
              top: null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black,
                      Colors.black.withAlpha(0),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(movie.title, style: const TextStyle(color: Colors.white),),
                ),
              ),
            ),
          ],
        ));
  }
}
