import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommendation_app/models/recommendation_option.dart';
import 'package:movie_recommendation_app/providers/movie_provider.dart';
import 'package:movie_recommendation_app/screens/home.dart';

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
  final List<int> _selectedGenreIds = [];

  final double minValueSlider = 20;
  final double maxValueSlider = 100;

  void _onGenreSelected(int genreId, bool selected) {
    setState(() {
      if (selected) {
        _selectedGenreIds.add(genreId);
      } else {
        _selectedGenreIds.remove(genreId);
      }
    });
  }

  void _submitPreferences() async {
    final options = RecommendationOption(
      includeCrew: _includeCrew,
      genreIds: _selectedGenreIds,
      movieCount: _moviecount.toInt(),
    );

    await ref.read(moviesProvider.notifier).loadMoviesBasedOnOptions(options);

    if (!mounted) return;
    // TODO: TERAZ TINDERSWAP TUTAJ MUSI BYĆ ELO
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (ctx) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresProvider);

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
            
            genresAsync.when(
              data: (genres) => Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: genres.map((genre) {
                  final id = genre['id'] as int;
                  final name = genre['name'] as String;
                  final isSelected = _selectedGenreIds.contains(id);

                  return FilterChip(
                    label: Text(name),
                    selected: isSelected,
                    onSelected: (selected) {
                      _onGenreSelected(id, selected);
                    },
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                  );
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
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