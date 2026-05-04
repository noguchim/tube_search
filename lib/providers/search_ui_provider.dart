import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/search_history_item.dart';

class SearchUIProvider extends ChangeNotifier {
  bool isOpen = false;
  List<SearchHistoryItem> history = [];
  bool _historyLoaded = false;
  static const int _historyMax = 12;
  static const String _historyKey = "search_history_v1";

  // =============================
  // UI制御
  // =============================
  void open() {
    if (isOpen) return;

    isOpen = true;
    notifyListeners();
  }

  void close() {
    if (!isOpen) return;

    isOpen = false;
    notifyListeners();
  }

  // =============================
  // 🔥 Load
  // =============================
  Future<void> loadHistory() async {
    if (_historyLoaded) return;
    _historyLoaded = true;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_historyKey) ?? [];

    history =
        list.map((e) => SearchHistoryItem.fromJson(jsonDecode(e))).toList();

    notifyListeners(); // ←初回だけOK
  }

  // =============================
  // 🔥 Save（今回の本体）
  // =============================
  Future<void> saveHistory(SearchHistoryItem item) async {
    final next = [
      item,
      ...history.where((e) => !(e.type == item.type &&
          e.keyword == item.keyword &&
          e.categoryId == item.categoryId)),
    ];

    if (next.length > _historyMax) {
      next.removeRange(_historyMax, next.length);
    }

    history = next;

    notifyListeners(); // ←UI更新

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _historyKey,
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  // =============================
  // 🔥 Remove
  // =============================
  Future<void> removeHistoryItem(String title) async {
    history = history.where((e) => e.title != title).toList(growable: false);

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _historyKey,
      history.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  // =============================
  // 🔥 Clear
  // =============================
  Future<void> clearHistory() async {
    history = [];
    _historyLoaded = false;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
