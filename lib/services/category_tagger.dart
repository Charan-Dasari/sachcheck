/// Keyword-based category tagger for news headlines.
///
/// Scans headline text for category-specific keywords and returns
/// the best-matching category tag.
class CategoryTagger {
  static const Map<String, List<String>> _keywords = {
    'Politics': [
      'government', 'minister', 'president', 'pm', 'parliament', 'election',
      'congress', 'bjp', 'aap', 'vote', 'political', 'opposition', 'senate',
      'policy', 'cabinet', 'legislation', 'democrat', 'republican', 'law',
      'bill', 'governor', 'mayor', 'diplomat', 'ambassador', 'campaign',
      'coalition', 'constituency', 'mla', 'mp', 'lok sabha', 'rajya sabha',
    ],
    'Health': [
      'health', 'covid', 'virus', 'hospital', 'doctor', 'vaccine', 'medical',
      'disease', 'patient', 'treatment', 'pandemic', 'epidemic', 'who',
      'symptom', 'surgery', 'pharma', 'drug', 'medicine', 'infection',
      'mental health', 'cancer', 'diabetes', 'heart', 'nutrition', 'fitness',
    ],
    'Science': [
      'science', 'research', 'study', 'nasa', 'isro', 'space', 'planet',
      'climate', 'environment', 'discovery', 'ai', 'artificial intelligence',
      'robot', 'quantum', 'genome', 'evolution', 'physics', 'chemistry',
      'biology', 'experiment', 'laboratory', 'scientist', 'innovation',
    ],
    'Finance': [
      'market', 'stock', 'share', 'sensex', 'nifty', 'rupee', 'dollar',
      'economy', 'gdp', 'inflation', 'rbi', 'bank', 'investment', 'tax',
      'budget', 'revenue', 'profit', 'loss', 'trade', 'export', 'import',
      'crypto', 'bitcoin', 'forex', 'startup', 'funding', 'ipo', 'mutual fund',
    ],
    'Sports': [
      'cricket', 'football', 'soccer', 'tennis', 'match', 'tournament',
      'ipl', 'world cup', 'olympics', 'goal', 'wicket', 'score', 'team',
      'player', 'coach', 'championship', 'medal', 'race', 'league', 'fifa',
      'bcci', 'icc', 'hockey', 'badminton', 'kabaddi', 'batting', 'bowling',
    ],
    'Technology': [
      'tech', 'technology', 'app', 'software', 'google', 'apple', 'microsoft',
      'samsung', 'iphone', 'android', 'internet', 'cyber', 'hack', 'data',
      'cloud', 'startup', 'digital', '5g', 'chip', 'semiconductor', 'meta',
      'facebook', 'twitter', 'instagram', 'whatsapp', 'elon musk', 'tesla',
    ],
    'Entertainment': [
      'bollywood', 'hollywood', 'movie', 'film', 'actor', 'actress', 'music',
      'song', 'album', 'concert', 'celebrity', 'oscar', 'grammy', 'award',
      'netflix', 'series', 'drama', 'comedy', 'star', 'director', 'box office',
      'release', 'trailer', 'premiere', 'ott', 'streaming',
    ],
  };

  /// Returns the most likely category for a headline, or 'General' if no match.
  static String categorize(String headline) {
    final lower = headline.toLowerCase();
    int bestScore = 0;
    String bestCategory = 'General';

    for (final entry in _keywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
      }
    }

    return bestCategory;
  }

  /// Returns the icon for a category.
  static String icon(String category) {
    switch (category) {
      case 'Politics':
        return '🏛️';
      case 'Health':
        return '🏥';
      case 'Science':
        return '🔬';
      case 'Finance':
        return '💰';
      case 'Sports':
        return '⚽';
      case 'Technology':
        return '💻';
      case 'Entertainment':
        return '🎬';
      default:
        return '📰';
    }
  }
}
