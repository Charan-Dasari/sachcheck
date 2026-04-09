import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sachcheck/models/history_item.dart';
import 'package:sachcheck/models/verification_result.dart';
import 'package:sachcheck/services/image_storage_service.dart';
import 'package:uuid/uuid.dart';

class HistoryNotifier extends StateNotifier<List<HistoryItem>> {
  final Box<HistoryItem> _box;

  HistoryNotifier(this._box) : super(_box.values.toList().reversed.toList());

  /// Adds a verification result to history.
  /// Copies the source image to persistent app storage so it survives
  /// temp-cache clearing.
  /// Also serializes matched articles as JSON for offline caching.
  Future<void> addResult(VerificationResult result) async {
    // Persist the screenshot so it doesn't vanish with the temp cache
    String persistedPath = result.imagePath;
    if (result.imagePath.isNotEmpty) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final storage = ImageStorageService(appDir.path);
        persistedPath = await storage.persistImage(result.imagePath);
      } catch (_) {
        // If persistence fails, fall back to original path
      }
    }

    // Serialize matched articles for offline viewing
    String? articlesJson;
    if (result.matchedArticles.isNotEmpty) {
      articlesJson = jsonEncode(
        result.matchedArticles.map((a) => a.toJson()).toList(),
      );
    }

    final item = HistoryItem(
      id: const Uuid().v4(),
      headline: result.headline,
      verdict: result.verdict.storageKey,
      score: result.topScore,
      checkedAt: result.checkedAt,
      imagePath: persistedPath,
      matchedArticlesJson: articlesJson,
      category: result.category,
    );
    _box.add(item);
    state = _box.values.toList().reversed.toList();
  }

  void deleteItem(int index) {
    final reversedIndex = _box.length - 1 - index;
    final item = _box.values.toList()[reversedIndex];
    item.delete();
    state = _box.values.toList().reversed.toList();
  }

  Future<void> clearAll() async {
    await _box.clear();
    state = [];
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryItem>>((ref) {
  final box = Hive.box<HistoryItem>('history');
  return HistoryNotifier(box);
});
