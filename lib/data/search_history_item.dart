class SearchHistoryItem {
  final String type; // search / trending / category
  final String title;
  final String? keyword;
  final String? categoryId;

  SearchHistoryItem({
    required this.type,
    required this.title,
    this.keyword,
    this.categoryId,
  });

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "title": title,
      "keyword": keyword,
      "categoryId": categoryId,
    };
  }

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      type: json["type"],
      title: json["title"],
      keyword: json["keyword"],
      categoryId: json["categoryId"],
    );
  }
}
