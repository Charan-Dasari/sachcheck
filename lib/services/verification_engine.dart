import 'package:sachcheck/models/verification_result.dart';
import 'package:sachcheck/services/category_tagger.dart';
import 'package:sachcheck/services/news_api_service.dart';

class VerificationEngine {
  final NewsApiService _newsService;

  VerificationEngine(this._newsService);

  Future<VerificationResult> verify({
    required String rawText,
    required String headline,
    required String imagePath,
  }) async {
    await _newsService.loadApiKey();

    // ── Step 1: Absurdity / Implausibility Pre-Check ──────────────────────
    final flags = <String>[];
    final absurdityResult = _detectAbsurdity(headline);
    flags.addAll(absurdityResult.flags);
    final bool isAbsurd = absurdityResult.isAbsurd;

    // ── Step 2: Fetch articles from all sources ───────────────────────────
    List<Map<String, dynamic>> rawArticles = [];
    try {
      rawArticles = await _newsService.fetchArticles(headline);
    } catch (_) {
      return VerificationResult(
        verdict: Verdict.notVerified,
        headline: headline,
        rawText: rawText,
        matchedArticles: [],
        topScore: 0.0,
        checkedAt: DateTime.now(),
        imagePath: imagePath,
        category: CategoryTagger.categorize(headline),
        confidenceLevel: 'Low',
        flags: isAbsurd ? flags : ['Network error — could not reach sources'],
      );
    }

    if (rawArticles.isEmpty) {
      if (isAbsurd) flags.add('No matching coverage found in any source');
      return VerificationResult(
        verdict: Verdict.notVerified,
        headline: headline,
        rawText: rawText,
        matchedArticles: [],
        topScore: 0.0,
        checkedAt: DateTime.now(),
        imagePath: imagePath,
        category: CategoryTagger.categorize(headline),
        confidenceLevel: 'Low',
        flags: isAbsurd ? flags : ['No coverage found in any trusted source'],
      );
    }

    // ── Step 3: Score each article ────────────────────────────────────────
    final cleanHeadline = _normalize(headline);
    final headlineKeywords = _extractSignificantWords(cleanHeadline);
    final coreSubjects = _extractCoreSubjects(headline);

    final scoredArticles = rawArticles.map((json) {
      final articleTitle = _normalize((json['title'] ?? '').toString());
      final articleDesc = _normalize((json['description'] ?? '').toString());

      // Base similarity scores
      final titleDice = _diceCoefficient(cleanHeadline, articleTitle);
      final titleKeyword = _weightedKeywordOverlap(cleanHeadline, articleTitle);
      final descDice = _diceCoefficient(cleanHeadline, articleDesc);
      final descKeyword = _weightedKeywordOverlap(cleanHeadline, articleDesc);

      // Combined base score (title weighted more than description)
      double baseScore = (
        (titleDice * 0.35 + titleKeyword * 0.65) * 0.75 +
        (descDice * 0.35 + descKeyword * 0.65) * 0.25
      );

      // ── Semantic subject match penalty ──────────────────────────────
      // Check if the article is actually about the same core subject
      final subjectMatch = _coreSubjectMatch(coreSubjects, articleTitle, articleDesc);
      if (!subjectMatch && baseScore > 0.1) {
        // Article shares keywords but is NOT about the same subject
        baseScore *= 0.25; // Heavy penalty
      }

      // ── Headline coverage check ─────────────────────────────────────
      // Penalize if less than 40% of headline keywords appear in article
      final coverage = _headlineCoverage(headlineKeywords, articleTitle, articleDesc);
      if (coverage < 0.4) {
        baseScore *= 0.5;
      }

      // ── Source tier weighting ────────────────────────────────────────
      final article = Article.fromJson(json, baseScore);
      final tierMultiplier = _sourceTierMultiplier(article.reliabilityTier);
      final finalScore = (baseScore * tierMultiplier).clamp(0.0, 1.0);

      return Article.fromJson(json, finalScore);
    }).toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    // Keep only articles with meaningful relevance
    final relevant = scoredArticles.where((a) => a.matchScore >= 0.08).toList();
    final topScore = relevant.isNotEmpty ? relevant.first.matchScore : 0.0;

    // ── Step 4: Consensus factor ──────────────────────────────────────────
    // Multiple sources agreeing increases confidence
    final highMatchCount = relevant.where((a) => a.matchScore >= 0.30).length;
    final consensusBonus = highMatchCount >= 3 ? 0.05 : 0.0;
    final adjustedScore = (topScore + consensusBonus).clamp(0.0, 1.0);

    // ── Step 5: Determine verdict ─────────────────────────────────────────
    Verdict verdict;
    String confidenceLevel;

    if (isAbsurd && adjustedScore < 0.65) {
      // Absurdity detected and no strong corroboration → force Not Verified
      verdict = Verdict.notVerified;
      confidenceLevel = 'High';
      if (!flags.contains('No strong corroboration found for this extraordinary claim')) {
        flags.add('No strong corroboration found for this extraordinary claim');
      }
    } else if (adjustedScore >= 0.55) {
      verdict = Verdict.verified;
      confidenceLevel = highMatchCount >= 3 ? 'High' : 'Medium';
    } else if (adjustedScore >= 0.30) {
      verdict = Verdict.needsCaution;
      confidenceLevel = 'Medium';
    } else {
      verdict = Verdict.notVerified;
      confidenceLevel = adjustedScore >= 0.15 ? 'Medium' : 'High';
    }

    return VerificationResult(
      verdict: verdict,
      headline: headline,
      rawText: rawText,
      matchedArticles: relevant.take(5).toList(),
      topScore: adjustedScore,
      checkedAt: DateTime.now(),
      imagePath: imagePath,
      category: CategoryTagger.categorize(headline),
      confidenceLevel: confidenceLevel,
      flags: flags.isEmpty ? [] : flags,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ABSURDITY / IMPLAUSIBILITY DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  _AbsurdityResult _detectAbsurdity(String headline) {
    final lower = headline.toLowerCase().trim();
    final flags = <String>[];
    bool isAbsurd = false;

    // ── Death hoax patterns ───────────────────────────────────────────────
    final deathPatterns = [
      RegExp(r'\b(died|dead|death|killed|assassinated|murdered|passes away|passed away|rip)\b', caseSensitive: false),
    ];
    // Check if this looks like a death claim about a public figure
    final prominentFigures = [
      'modi', 'pm modi', 'narendra modi', 'rahul gandhi', 'amit shah',
      'yogi', 'kejriwal', 'mamata', 'biden', 'trump', 'obama', 'putin',
      'xi jinping', 'elon musk', 'shah rukh', 'virat kohli', 'sachin',
      'ambani', 'adani', 'gates', 'zuckerberg',
    ];
    for (final pattern in deathPatterns) {
      if (pattern.hasMatch(lower)) {
        for (final figure in prominentFigures) {
          if (lower.contains(figure)) {
            flags.add('⚠ Possible death hoax pattern detected');
            isAbsurd = true;
            break;
          }
        }
        if (isAbsurd) break;
      }
    }

    // ── Fabricated / impossible events ─────────────────────────────────────
    final fabricatedPatterns = [
      RegExp(r'world\s*war\s*[4-9]', caseSensitive: false),
      RegExp(r'world\s*war\s*(iv|v|vi|vii|viii|ix|x)\b', caseSensitive: false),
      RegExp(r'ww[4-9]\b', caseSensitive: false),
      RegExp(r'nuclear\s*(war|attack|bomb)\s*(on|in)\s*(india|usa|america|china|russia)', caseSensitive: false),
      RegExp(r'(alien|ufo|zombie)\s*(attack|invasion|landed)', caseSensitive: false),
      RegExp(r'(india|china|pakistan|usa)\s*(conquered|invaded|destroyed|nuked)\s*(india|china|pakistan|usa|the world)', caseSensitive: false),
      RegExp(r'(india|pakistan)\s+won\s+(world\s*war|ww)', caseSensitive: false),
      RegExp(r'(end\s*of\s*the\s*world|earth\s*destroyed|apocalypse\s*confirmed)', caseSensitive: false),
    ];
    for (final pattern in fabricatedPatterns) {
      if (pattern.hasMatch(lower)) {
        flags.add('⚠ References a fabricated or impossible event');
        isAbsurd = true;
        break;
      }
    }

    // ── Sensationalist clickbait patterns ──────────────────────────────────
    final clickbaitPatterns = [
      RegExp(r"(you\s*won'?t\s*believe|shocking\s*truth|this\s*will\s*blow\s*your\s*mind)", caseSensitive: false),
      RegExp(r'(breaking|urgent|leaked).*?(secret|exposed|revealed)', caseSensitive: false),
      RegExp(r"(government|nasa|who)\s*(hiding|covering\s*up|doesn'?t\s*want)", caseSensitive: false),
    ];
    for (final pattern in clickbaitPatterns) {
      if (pattern.hasMatch(lower)) {
        flags.add('⚠ Sensationalist/clickbait language detected');
        isAbsurd = true;
        break;
      }
    }

    return _AbsurdityResult(isAbsurd: isAbsurd, flags: flags);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE SUBJECT MATCHING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extracts the 1-3 most significant noun phrases from a headline
  List<String> _extractCoreSubjects(String headline) {
    final lower = headline.toLowerCase();
    final subjects = <String>[];

    // Named entity-like extraction: multi-word capitalized phrases from original
    final namePattern = RegExp(r'[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+');
    for (final match in namePattern.allMatches(headline)) {
      subjects.add(match.group(0)!.toLowerCase());
    }

    // Also grab known proper noun patterns (PM Modi, World War, etc.)
    final knownPatterns = [
      RegExp(r'pm\s+modi', caseSensitive: false),
      RegExp(r'narendra\s+modi', caseSensitive: false),
      RegExp(r'rahul\s+gandhi', caseSensitive: false),
      RegExp(r'world\s*war\s*\w+', caseSensitive: false),
      RegExp(r'ww\d+', caseSensitive: false),
    ];
    for (final p in knownPatterns) {
      final m = p.firstMatch(lower);
      if (m != null) subjects.add(m.group(0)!.toLowerCase().trim());
    }

    // If we found nothing specific, use the longest non-stop-word
    if (subjects.isEmpty) {
      final words = _extractSignificantWords(_normalize(headline));
      // Take the top 2 longest words as core subjects
      final sorted = words.toList()..sort((a, b) => b.length.compareTo(a.length));
      subjects.addAll(sorted.take(2));
    }

    return subjects;
  }

  /// Checks if at least one core subject appears in the article text
  bool _coreSubjectMatch(List<String> coreSubjects, String articleTitle, String articleDesc) {
    if (coreSubjects.isEmpty) return true; // No subjects extracted = can't filter

    final combined = '$articleTitle $articleDesc';
    for (final subject in coreSubjects) {
      // For multi-word subjects, require the full phrase
      if (subject.contains(' ')) {
        if (combined.contains(subject)) return true;
      } else {
        // Single word — check if it exists
        if (RegExp('\\b${RegExp.escape(subject)}\\b').hasMatch(combined)) return true;
      }
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCORING UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Set<String> _extractSignificantWords(String normalized) {
    const stopWords = {
      'the', 'a', 'an', 'in', 'on', 'at', 'is', 'was', 'of', 'to', 'and',
      'or', 'for', 'by', 'with', 'from', 'as', 'its', 'it', 'be', 'are',
      'that', 'this', 'have', 'has', 'had', 'not', 'but', 'he', 'she', 'they',
      'says', 'said', 'told', 'after', 'over', 'amid', 'how', 'what', 'why',
      'when', 'where', 'who', 'which', 'will', 'can', 'been', 'were', 'did',
      'does', 'do', 'about', 'into', 'then', 'than', 'just', 'also', 'more',
      'new', 'now', 'may', 'between', 'under', 'like', 'most', 'very',
      'get', 'got', 'much', 'own', 'our', 'his', 'her', 'their',
      'being', 'up', 'out', 'so', 'no', 'if', 'some', 'all', 'would',
      'could', 'should', 'shall', 'might', 'must',
    };
    return normalized
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toSet();
  }

  /// Checks what fraction of headline keywords appear in the article
  double _headlineCoverage(Set<String> headlineKeywords, String articleTitle, String articleDesc) {
    if (headlineKeywords.isEmpty) return 0.0;
    final articleText = '$articleTitle $articleDesc';
    int found = 0;
    for (final word in headlineKeywords) {
      if (articleText.contains(word)) found++;
    }
    return found / headlineKeywords.length;
  }

  /// Weighted keyword overlap — longer/rarer words count more
  double _weightedKeywordOverlap(String a, String b) {
    final wordsA = _extractSignificantWords(a);
    final wordsB = _extractSignificantWords(b);
    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;

    double matchWeight = 0.0;
    double totalWeight = 0.0;

    for (final word in wordsA) {
      // Weight: longer words and less common words are more significant
      final weight = word.length > 5 ? 2.0 : (word.length > 3 ? 1.0 : 0.5);
      totalWeight += weight;
      if (wordsB.contains(word)) {
        matchWeight += weight;
      }
    }

    return totalWeight == 0 ? 0.0 : matchWeight / totalWeight;
  }

  /// Source tier multiplier — establishes how much to trust a source match
  double _sourceTierMultiplier(SourceTier tier) {
    switch (tier) {
      case SourceTier.established:
        return 1.0;
      case SourceTier.aggregator:
        return 0.9;
      case SourceTier.reference:
        return 0.55; // Wikipedia matches tangential topics too easily
      case SourceTier.userAdded:
        return 0.5;
    }
  }

  double _diceCoefficient(String s1, String s2) {
    if (s1.length < 2 || s2.length < 2) return 0.0;
    final bigrams1 = _getBigrams(s1);
    final bigrams2 = _getBigrams(s2);
    int intersection = 0;
    final temp = List<String>.from(bigrams2);
    for (final bigram in bigrams1) {
      final idx = temp.indexOf(bigram);
      if (idx >= 0) {
        intersection++;
        temp.removeAt(idx);
      }
    }
    return (2.0 * intersection) / (bigrams1.length + bigrams2.length);
  }

  List<String> _getBigrams(String s) {
    final bigrams = <String>[];
    for (int i = 0; i < s.length - 1; i++) {
      bigrams.add(s.substring(i, i + 2));
    }
    return bigrams;
  }
}

/// Internal helper for absurdity detection results
class _AbsurdityResult {
  final bool isAbsurd;
  final List<String> flags;
  const _AbsurdityResult({required this.isAbsurd, required this.flags});
}
