import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/widgets/info_step.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_creation_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'NAZWA APLIKACJI - App for Recommending Movies',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Stop arguing over movie night. Swipe movies on your own, and let the app instantly find the perfect match for everyone.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const InfoStep(
            icon: Icons.groups_2_rounded,
            title: 'Group Up',
            description:
                'Create a lobby or join your friends with a simple code. Everyone stays in sync, making it easy to choose a movie together in real time.',
            stepNumber: '1',
          ),
          const InfoStep(
            icon: Icons.tune_rounded,
            title: 'Set Your Preferences',
            description:
                'Choose the genres you’re in the mood for and set how many movies you want to swipe through. You can also swipe by cast.',
            stepNumber: '2',
          ),
          const InfoStep(
            icon: Icons.swipe_rounded,
            title: 'Start Swiping',
            description:
                'The fun part! Swipe right to like a movie and give it a star rating, or swipe left to pass. Tap “Not Seen” if you haven’t watched it yet.',
            stepNumber: '3',
          ),
          const InfoStep(
            icon: Icons.add_reaction_rounded,
            title: 'React & Decide',
            description:
                'After everyone finishes swiping, the app shows personalized recommendations. React with emojis to say how much you want to watch each one.',
            stepNumber: '4',
          ),
          const InfoStep(
            icon: Icons.local_movies_rounded,
            title: 'It’s a Match!',
            description:
                'Based on everyone’s reactions, the app calculates a consensus score and reveals the top three movies. Popcorn time!',
            stepNumber: '5',
            isLast: true,
          ),
          Column(
            children: [
              Text(
                'About the Author',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Kacper Straszak',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
