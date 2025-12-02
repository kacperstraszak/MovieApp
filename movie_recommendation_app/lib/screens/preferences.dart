import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/recommendation_option.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() {
    return _PreferencesScreenState();
  }
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  bool _includeCrew = false;
  double _moviecount = 50;
  final List<String> _usersGenres = [];

  final double minValueSlider = 20;
  final double maxValueSlider = 100;

  final List<String> _allGenres = [
    'Action',
    'Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Family',
    'Fantasy',
    'History',
    'Horror',
    'Music',
    'Mystery',
    'Romance',
    'Science Fiction',
    'Thriller',
    'War',
    'Western'
  ];

  void _onGenreSelected(String genre, bool selected) {
    setState(() {
      if (selected) {
        _usersGenres.add(genre);
      } else {
        _usersGenres.remove(genre);
      }
    });
  }

  void _submitPreferences() {
    final option = RecommendationOption(
      includeCrew: _includeCrew,
      genres: _usersGenres,
      movieCount: _moviecount.toInt(),
    );

    //TODO: POBIERANIE FILMÓW I 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your recommendation options!',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Include Cast and Crew'),
              contentPadding: EdgeInsets.zero,
              value: _includeCrew,
              onChanged: (value) {
                setState(() {
                  _includeCrew = value;
                });
              },
            ),
            const Divider(height: 32),
            Text(
              'How many items would you like to swipe?',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            Text(
              'More items swiped result in better recommendations',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  minValueSlider.round().toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: Slider(
                    label: _moviecount.round().toString(),
                    value: _moviecount,
                    min: minValueSlider,
                    max: maxValueSlider,
                    divisions: ((maxValueSlider - minValueSlider) / 10)
                        .round()
                        .toInt(),
                    onChanged: (value) {
                      setState(() {
                        _moviecount = value;
                      });
                    },
                  ),
                ),
                Text(
                  maxValueSlider.round().toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Center(
              child: Text(
                'Selected ${_moviecount.round()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(height: 32),
            Text(
              'Choose your Favorite Genres',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _allGenres.map((genre) {
                final isSelected = _usersGenres.contains(genre);
                return FilterChip(
                  label: Text(genre),
                  selected: isSelected,
                  onSelected: (selected) {
                    _onGenreSelected(genre, selected);
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitPreferences,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Start Swiping!',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
