class TrendingKeyword {
  final String keyword;
  final double score;

  const TrendingKeyword({
    required this.keyword,
    required this.score,
  });

  factory TrendingKeyword.fromJson(Map<String, dynamic> json) {
    return TrendingKeyword(
      keyword: json["keyword"] ?? "",
      score: (json["score"] as num?)?.toDouble() ?? 0,
    );
  }
}
