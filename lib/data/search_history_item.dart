class SearchHistoryItem {
  final String type; // search / trending / category
  final String title;
  final String? keyword;
  final String? categoryId;
  final String searchMode;

  SearchHistoryItem({
    required this.type,
    required this.title,
    this.keyword,
    this.categoryId,
    required this.searchMode,
  });

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "title": title,
      "keyword": keyword,
      "categoryId": categoryId,
      "searchMode": searchMode,
    };
  }

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      type: json["type"],
      title: json["title"],
      keyword: json["keyword"],
      categoryId: json["categoryId"],
      searchMode: json["searchMode"],
    );
  }
}
