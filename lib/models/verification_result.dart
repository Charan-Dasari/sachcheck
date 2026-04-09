class Article {
  final String title;
  final String source;
  final String url;
  final String? imageUrl;
  final DateTime? publishedAt;
  final double matchScore;

  const Article({
    required this.title,
    required this.source,
    required this.url,
    this.imageUrl,
    this.publishedAt,
    this.matchScore = 0.0,
  });

  factory Article.fromJson(Map<String, dynamic> json, double score) {
    return Article(
      title: json['title'] ?? '',
      source: json['source']?['name'] ?? json['source'] ?? 'Unknown',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'] ?? json['image'],
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'])
          : null,
      matchScore: score,
    );
  }

  /// Serializes the article to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'title': title,
        'source': source,
        'url': url,
        'imageUrl': imageUrl,
        'publishedAt': publishedAt?.toIso8601String(),
        'matchScore': matchScore,
      };

  /// Deserializes an article from a JSON map (cached in Hive).
  factory Article.fromCacheJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      source: json['source'] ?? 'Unknown',
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'],
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'])
          : null,
      matchScore: (json['matchScore'] ?? 0.0).toDouble(),
    );
  }

  // ── Source Reliability ────────────────────────────────────────────────────

  /// Known established news agencies (tier 1 — most trusted)
  static const _established = {
    // International wire services
    'ap news', 'associated press', 'reuters', 'afp', 'pti',
    'ani', 'ians', 'united news of india',
    // Major Indian sources
    'ndtv', 'the hindu', 'indian express', 'hindustan times',
    'times of india', 'the print', 'the wire', 'india today',
    'zee news', 'aaj tak', 'news18', 'republic',
    'deccan herald', 'deccan chronicle', 'scroll', 'firstpost',
    'livemint', 'mint', 'economic times', 'business standard',
    'the quint', 'newslaundry', 'the free press journal',
    'telegraph india', 'the statesman', 'tribune india',
    'outlook india', 'frontline', 'the week', 'dna india',
    'moneycontrol', 'financial express', 'business today',
    // International broadcasters
    'bbc', 'cnn', 'al jazeera', 'the guardian',
    'washington post', 'new york times', 'nyt', 'abc news',
    'nbc news', 'cbs news', 'sky news', 'france 24', 'dw news',
    'south china morning post', 'the independent', 'the telegraph',
  };

  /// Aggregators (tier 2)
  static const _aggregators = {
    'google news', 'bing news', 'duckduckgo', 'yahoo news',
    'msn', 'flipboard', 'inshorts',
  };

  /// Reference sources (tier 3)
  static const _reference = {
    'wikipedia', 'wikimedia',
  };

  /// Returns the reliability tier for this source.
  SourceTier get reliabilityTier {
    final lower = source.toLowerCase();
    if (_established.any((s) => lower.contains(s))) return SourceTier.established;
    if (_aggregators.any((s) => lower.contains(s))) return SourceTier.aggregator;
    if (_reference.any((s) => lower.contains(s))) return SourceTier.reference;
    return SourceTier.userAdded;
  }
}

enum SourceTier { established, aggregator, reference, userAdded }

extension SourceTierExtension on SourceTier {
  String get label {
    switch (this) {
      case SourceTier.established: return 'Established';
      case SourceTier.aggregator: return 'Aggregator';
      case SourceTier.reference: return 'Reference';
      case SourceTier.userAdded: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case SourceTier.established: return '🟢';
      case SourceTier.aggregator: return '🟡';
      case SourceTier.reference: return '🔵';
      case SourceTier.userAdded: return '⚪';
    }
  }
}

enum Verdict { verified, needsCaution, notVerified }

extension VerdictExtension on Verdict {
  String get label {
    switch (this) {
      case Verdict.verified:
        return 'Verified';
      case Verdict.needsCaution:
        return 'Needs Caution';
      case Verdict.notVerified:
        return 'Not Verified';
    }
  }

  String get emoji {
    switch (this) {
      case Verdict.verified:
        return '✅';
      case Verdict.needsCaution:
        return '⚠️';
      case Verdict.notVerified:
        return '❌';
    }
  }

  String get description {
    switch (this) {
      case Verdict.verified:
        return 'This headline matches articles from trusted news sources.';
      case Verdict.needsCaution:
        return 'Partial matches found. Verify with official sources before sharing.';
      case Verdict.notVerified:
        return 'No matching coverage found in trusted sources. Exercise caution.';
    }
  }

  String get storageKey {
    switch (this) {
      case Verdict.verified: return 'verified';
      case Verdict.needsCaution: return 'needs_caution';
      case Verdict.notVerified: return 'not_verified';
    }
  }
}

class VerificationResult {
  final Verdict verdict;
  final String headline;
  final String rawText;
  final List<Article> matchedArticles;
  final double topScore;
  final DateTime checkedAt;
  final String imagePath;
  final String category;
  final String confidenceLevel;
  final List<String> flags;

  const VerificationResult({
    required this.verdict,
    required this.headline,
    required this.rawText,
    required this.matchedArticles,
    required this.topScore,
    required this.checkedAt,
    required this.imagePath,
    this.category = 'General',
    this.confidenceLevel = 'Medium',
    this.flags = const [],
  });
}
