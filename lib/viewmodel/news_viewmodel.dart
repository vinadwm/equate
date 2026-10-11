import 'package:flutter/foundation.dart';

import 'package:equate/model/news_model.dart';
import 'package:equate/service/news_service.dart';

/// Dipakai bersama oleh tab Berita dan banner di Beranda,
/// jadi berita hanya diambil sekali.
class NewsViewModel extends ChangeNotifier {
  NewsViewModel._();
  static final NewsViewModel instance = NewsViewModel._();

  List<NewsItem> items = [];
  bool isLoading = false;
  bool hasError = false;
  String? selectedSource; // null = semua

  List<NewsItem> get filtered => selectedSource == null
      ? items
      : items.where((e) => e.source == selectedSource).toList();

  List<String> get sources {
    final set = <String>{};
    for (final e in items) {
      set.add(e.source);
    }
    return set.toList();
  }

  Future<void> load({bool force = false}) async {
    if (isLoading) return;
    if (!force && items.isNotEmpty) return;

    isLoading = true;
    hasError = false;
    notifyListeners();

    try {
      final result = await NewsService.fetchAll();
      items = result;
      hasError = result.isEmpty;
    } catch (_) {
      hasError = true;
    }

    isLoading = false;
    notifyListeners();
  }

  void selectSource(String? source) {
    selectedSource = source;
    notifyListeners();
  }
}