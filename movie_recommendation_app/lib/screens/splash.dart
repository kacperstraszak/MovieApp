import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Recommendation App'),
        actions: [
          IconButton(
            onPressed: () {
              supabase.auth.signOut();
            },
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: preloader,
    );
  }
}
