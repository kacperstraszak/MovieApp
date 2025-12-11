import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/utils/constants.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: preloader,
    );
  }
}
