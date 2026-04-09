import 'package:hive/hive.dart';

part 'history_item.g.dart';

@HiveType(typeId: 0)
class HistoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String headline;

  @HiveField(2)
  final String verdict; // 'verified', 'not_verified', 'needs_caution'

  @HiveField(3)
  final double score;

  @HiveField(4)
  final DateTime checkedAt;

  @HiveField(5)
  final String imagePath;

  @HiveField(6)
  final String? matchedArticlesJson; // JSON string of matched articles

  @HiveField(7)
  final String? category; // 'Politics', 'Health', 'Science', etc.

  HistoryItem({
    required this.id,
    required this.headline,
    required this.verdict,
    required this.score,
    required this.checkedAt,
    required this.imagePath,
    this.matchedArticlesJson,
    this.category,
  });
}
