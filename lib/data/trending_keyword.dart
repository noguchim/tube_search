class TrendingKeyword {
  final String keyword;
  final String region;
  final DateTime? generatedAt;

  const TrendingKeyword({
    required this.keyword,
    required this.region,
    this.generatedAt,
  });

  factory TrendingKeyword.fromApi({
    required String keyword,
    required String region,
    DateTime? generatedAt,
  }) {
    return TrendingKeyword(
      keyword: keyword,
      region: region,
      generatedAt: generatedAt,
    );
  }
}
