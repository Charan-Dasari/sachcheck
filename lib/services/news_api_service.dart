import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Multi-source news verification service.
///
/// Sources (all free, no key required unless noted):
///   1. Wikipedia Search API
///   2. DuckDuckGo Instant Answer API
///   3. Google News RSS
///   4. Bing News (via Google News-style RSS)
///   5. Associated Press News (via RSS)
///   6. NewsAPI.org (optional, user-provided key)
class NewsApiService {
  static const _prefKey = 'news_api_key';

  String _apiKey = '';

  Future<void> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey) ?? '';
    if (saved.isNotEmpty) _apiKey = saved;
  }

  void setApiKey(String key) => _apiKey = key;
  String get apiKey => _apiKey;
  bool get hasApiKey => _apiKey.isNotEmpty;

  /// Main entry point. Returns article-like maps:
  ///   { 'title', 'description', 'source': {'name'}, 'url', 'publishedAt' }
  Future<List<Map<String, dynamic>>> fetchArticles(String query) async {
    final searchQuery = _extractKeywords(query);

    final futures = <Future<List<Map<String, dynamic>>>>[
      _fetchFromWikipedia(searchQuery),
      _fetchFromDuckDuckGo(searchQuery),
      _fetchFromGoogleNewsRss(searchQuery),
      _fetchFromBingNews(searchQuery),
      _fetchFromAssociatedPress(searchQuery),
      _fetchFromNDTV(searchQuery),
      _fetchFromHindustanTimes(searchQuery),
      _fetchFromIndiaTodayRss(searchQuery),
      _fetchFromTimesOfIndia(searchQuery),
      if (_apiKey.isNotEmpty) _fetchFromNewsApi(searchQuery),
    ];

    final allResults = <Map<String, dynamic>>[];
    final results = await Future.wait(futures);
    for (final list in results) {
      allResults.addAll(list);
    }

    // Deduplicate by URL
    final seen = <String>{};
    return allResults.where((a) {
      final url = (a['url'] ?? '').toString();
      if (url.isEmpty || seen.contains(url)) return false;
      seen.add(url);
      return true;
    }).toList();
  }

  // ── 1. Wikipedia Search API ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchFromWikipedia(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final uri = Uri.parse(
        'https://en.wikipedia.org/w/api.php'
        '?action=query&list=search&srsearch=$encoded'
        '&srlimit=8&format=json&origin=*',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final searchResults =
          (data['query']?['search'] as List<dynamic>?) ?? [];

      return searchResults.map<Map<String, dynamic>>((item) {
        final title = (item['title'] ?? '').toString();
        final snippet = (item['snippet'] ?? '')
            .toString()
            .replaceAll(RegExp(r'<[^>]+>'), '');
        return {
          'title': title,
          'description': snippet,
          'source': {'name': 'Wikipedia'},
          'url':
              'https://en.wikipedia.org/wiki/${Uri.encodeComponent(title)}',
          'publishedAt': null,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 2. DuckDuckGo Instant Answer API ─────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchFromDuckDuckGo(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final uri = Uri.parse(
        'https://api.duckduckgo.com/?q=$encoded&format=json&no_redirect=1&no_html=1',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = <Map<String, dynamic>>[];

      final abstract = (data['Abstract'] ?? '').toString();
      final abstractSource = (data['AbstractSource'] ?? '').toString();
      final abstractUrl = (data['AbstractURL'] ?? '').toString();
      if (abstract.isNotEmpty && abstractUrl.isNotEmpty) {
        results.add({
          'title': abstractSource.isNotEmpty ? abstractSource : query,
          'description': abstract,
          'source': {
            'name':
                abstractSource.isNotEmpty ? abstractSource : 'DuckDuckGo'
          },
          'url': abstractUrl,
          'publishedAt': null,
        });
      }

      final topics = (data['RelatedTopics'] as List<dynamic>?) ?? [];
      for (final topic in topics.take(5)) {
        if (topic is Map<String, dynamic>) {
          final text = (topic['Text'] ?? '').toString();
          final url = (topic['FirstURL'] ?? '').toString();
          if (text.isNotEmpty && url.isNotEmpty) {
            results.add({
              'title':
                  text.length > 80 ? '${text.substring(0, 80)}…' : text,
              'description': text,
              'source': {'name': 'DuckDuckGo'},
              'url': url,
              'publishedAt': null,
            });
          }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // ── 3. Google News RSS (free, no key) ────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchFromGoogleNewsRss(
      String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final uri = Uri.parse(
        'https://news.google.com/rss/search?q=$encoded&hl=en-IN&gl=IN&ceid=IN:en',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];

      return _parseRss(response.body, 'Google News');
    } catch (_) {
      return [];
    }
  }

  // ── 4. Bing News (free, RSS-like endpoint) ───────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchFromBingNews(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final uri = Uri.parse(
          'https://www.bing.com/news/search?q=$encoded&format=rss');
      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; SachDrishti/1.0)',
      }).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];

      return _parseRss(response.body, 'Bing News');
    } catch (_) {
      return [];
    }
  }

  // ── 5. Associated Press (AP News via Google News RSS filter) ──────────────
  Future<List<Map<String, dynamic>>> _fetchFromAssociatedPress(
      String query) async {
    try {
      final encoded = Uri.encodeComponent('$query site:apnews.com OR site:reuters.com');
      final uri = Uri.parse(
        'https://news.google.com/rss/search?q=$encoded&hl=en&gl=US&ceid=US:en',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];

      return _parseRss(response.body, 'AP/Reuters');
    } catch (_) {
      return [];
    }
  }

  // ── 6. NewsAPI.org (optional, richer results) ────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchFromNewsApi(String query) async {
    if (_apiKey.isEmpty) return [];
    try {
      final encoded = Uri.encodeComponent(query);
      final uri = Uri.parse(
        'https://newsapi.org/v2/everything?q=$encoded'
        '&sortBy=relevancy&pageSize=10&language=en',
      );
      final response = await http
          .get(uri, headers: {'X-Api-Key': _apiKey})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final articles = (data['articles'] as List<dynamic>?) ?? [];
      return articles.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ── RSS Parser (simple regex-based for <item> elements) ──────────────────
  List<Map<String, dynamic>> _parseRss(String xml, String sourceName) {
    final results = <Map<String, dynamic>>[];
    final itemPattern = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final titlePattern = RegExp(r'<title>(.*?)</title>', dotAll: true);
    final linkPattern = RegExp(r'<link>(.*?)</link>', dotAll: true);
    final pubDatePattern = RegExp(r'<pubDate>(.*?)</pubDate>', dotAll: true);
    final descPattern =
        RegExp(r'<description>(.*?)</description>', dotAll: true);

    final items = itemPattern.allMatches(xml);
    for (final item in items.take(8)) {
      final content = item.group(1) ?? '';
      final title = titlePattern.firstMatch(content)?.group(1) ?? '';
      final link = linkPattern.firstMatch(content)?.group(1) ?? '';
      final pubDate = pubDatePattern.firstMatch(content)?.group(1);
      final desc = descPattern.firstMatch(content)?.group(1) ?? '';

      if (title.isEmpty || link.isEmpty) continue;

      // Clean CDATA and HTML
      final cleanTitle = _stripCdata(title);
      final cleanDesc = _stripCdata(desc)
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .trim();

      DateTime? published;
      if (pubDate != null) {
        try {
          published = DateTime.tryParse(pubDate);
          published ??= _parseRfc2822(pubDate);
        } catch (_) {}
      }

      results.add({
        'title': cleanTitle,
        'description': cleanDesc,
        'source': {'name': sourceName},
        'url': link,
        'publishedAt': published?.toIso8601String(),
      });
    }
    return results;
  }

  String _stripCdata(String s) {
    return s
        .replaceAll(RegExp(r'<!\[CDATA\['), '')
        .replaceAll(RegExp(r'\]\]>'), '')
        .trim();
  }

  /// Best-effort RFC-2822 date parser ("Mon, 23 Mar 2026 12:00:00 GMT")
  DateTime? _parseRfc2822(String s) {
    try {
      const months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final parts = s.replaceAll(',', '').split(RegExp(r'\s+'));
      if (parts.length < 5) return null;
      final day = int.parse(parts[1]);
      final month = months[parts[2]] ?? 1;
      final year = int.parse(parts[3]);
      final timeParts = parts[4].split(':');
      return DateTime.utc(
        year,
        month,
        day,
        int.parse(timeParts[0]),
        timeParts.length > 1 ? int.parse(timeParts[1]) : 0,
        timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Keyword extraction ───────────────────────────────────────────────────────────────
  String _extractKeywords(String headline) {
    const fillerWords = {
      'says', 'said', 'told', 'reports', 'report', 'according',
      'amid', 'over', 'after', 'before', 'during', 'while',
      'has', 'have', 'had', 'been', 'being', 'will', 'would',
      'could', 'should', 'may', 'might', 'must', 'shall',
      'is', 'are', 'was', 'were', 'be',
      'the', 'a', 'an', 'in', 'on', 'at', 'of', 'to', 'and',
      'or', 'for', 'by', 'with', 'from', 'as', 'its', 'it',
      'that', 'this', 'but', 'he', 'she', 'they', 'we', 'our',
      'his', 'her', 'their', 'also', 'now', 'new', 'more',
      'up', 'take', 'takes', 'took', 'cases', 'number',
      'how', 'what', 'why', 'when', 'where', 'who', 'which',
    };

    final words = headline
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !fillerWords.contains(w.toLowerCase()))
        .take(6)
        .toList();

    return words.isEmpty ? headline : words.join(' ');
  }

  // ── 7. NDTV (via Google News RSS site filter) ─────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchFromNDTV(String query) async {
    try {
      final encoded = Uri.encodeComponent('$query site:ndtv.com');
      final uri = Uri.parse(
        'https://news.google.com/rss/search?q=$encoded&hl=en-IN&gl=IN&ceid=IN:en',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];
      return _parseRss(response.body, 'NDTV');
    } catch (_) {
      return [];
    }
  }

  // ── 8. Hindustan Times (via Google News RSS site filter) ─────────────────
  Future<List<Map<String, dynamic>>> _fetchFromHindustanTimes(String query) async {
    try {
      final encoded = Uri.encodeComponent('$query site:hindustantimes.com');
      final uri = Uri.parse(
        'https://news.google.com/rss/search?q=$encoded&hl=en-IN&gl=IN&ceid=IN:en',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];
      return _parseRss(response.body, 'Hindustan Times');
    } catch (_) {
      return [];
    }
  }

  // ── 9. India Today (via Google News RSS site filter) ─────────────────────
  Future<List<Map<String, dynamic>>> _fetchFromIndiaTodayRss(String query) async {
    try {
      final encoded = Uri.encodeComponent('$query site:indiatoday.in');
      final uri = Uri.parse(
        'https://news.google.com/rss/search?q=$encoded&hl=en-IN&gl=IN&ceid=IN:en',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];
      return _parseRss(response.body, 'India Today');
    } catch (_) {
      return [];
    }
  }

  // ── 10. Times of India (via Google News RSS site filter) ────────────────
  Future<List<Map<String, dynamic>>> _fetchFromTimesOfIndia(String query) async {
    try {
      final encoded = Uri.encodeComponent('$query site:timesofindia.indiatimes.com');
      final uri = Uri.parse(
        'https://news.google.com/rss/search?q=$encoded&hl=en-IN&gl=IN&ceid=IN:en',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return [];
      return _parseRss(response.body, 'Times of India');
    } catch (_) {
      return [];
    }
  }
}
