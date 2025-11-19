import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('Movie Recommendation App'),
      ),
      body: preloader,
    );
  }
}
