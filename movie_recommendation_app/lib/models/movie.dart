class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.posterPath,
    this.backdropPath,
    required this.releaseDate,
  });

  final int id;
  final String title;
  final String description;
  final String posterPath;
  final String? backdropPath;
  final String releaseDate;


  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      posterPath: json['poster_path'] as String? ?? '',
      backdropPath: json['backdrop_path'] as String?, 
      releaseDate: json['release'] as String? ?? 'Unknown',
    );
  }
}