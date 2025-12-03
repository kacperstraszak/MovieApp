class RecommendationOption {
  const RecommendationOption({
    this.includeCrew = false,
    this.genreIds = const [],
    this.movieCount = 20,
  });
  final bool includeCrew;
  final List<int> genreIds;
  final int movieCount;
}
