import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/models/movie.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(movie.title),
        ),
        body: ListView(
          children: [
            Image.network(movie.posterPath),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    movie.releaseDate,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(movie.description),
                ],
              ),
            ),
          ],
        ));
  }
}
