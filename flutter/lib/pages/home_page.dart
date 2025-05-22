import 'package:flutter/material.dart';
import 'package:movie_recommendation_app/components/menu.dart';
import 'package:movie_recommendation_app/main.dart';
import 'package:movie_recommendation_app/models/movie.dart';
import 'package:movie_recommendation_app/components/movie_element.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final moviesFuture = supabase
        .from('movies')
        .select()
        .withConverter<List<Movie>>(
            (data) => data.map(Movie.fromJson).toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('HomePage'),
      ),
      drawer: const MenuDrawer(),
      floatingActionButton: SpeedDial(
        activeIcon: Icons.close,
        icon: Icons.more_vert,
        overlayOpacity: 0.4,
        overlayColor: Colors.black,
        children: [
          SpeedDialChild(
            backgroundColor: const Color.fromARGB(255, 228, 117, 109),
            child: const Icon(Icons.groups_2),
            label: 'Create Group',
            onTap: () {
              print('2');
            },
          ),
          SpeedDialChild(
            backgroundColor: const Color.fromARGB(255, 228, 117, 109),
            child: const Icon(Icons.group_add),
            label: 'Join Group',
            onTap: () {
              print('3');
            },
          ),
          SpeedDialChild(
            backgroundColor: const Color.fromARGB(255, 228, 117, 109),
            child: const Icon(Icons.search),
            label: 'Search',
            onTap: () {
              print('1');
            },
          ),
        ],
      ),
      body: FutureBuilder(
          future: moviesFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final movies = snapshot.data!;
            return ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return MovieElement(movie: movie);
              },
            );
          }),
    );
  }
}
