class Movie {
  final int id;
  final String title;
  final String description;
  final String posterPath;
  final String releaseDate;

  Movie.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        title = json['title'] as String,
        description = json['description'] as String,
        posterPath = 'https://image.tmdb.org/t/p/w500${json['poster_path']}',
        releaseDate = json['release'] as String;
}
