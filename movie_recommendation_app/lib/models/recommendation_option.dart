class RecommendationOption {
  const RecommendationOption({
    this.genres = const [],
    this.includeCrew = false,
    this.movieCount = 50,
  });

  final bool includeCrew;
  final List<String> genres;
  final int movieCount;
}
