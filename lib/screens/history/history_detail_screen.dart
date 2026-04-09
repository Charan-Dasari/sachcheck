import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/models/history_item.dart';
import 'package:sachcheck/models/verification_result.dart';

class HistoryDetailScreen extends StatefulWidget {
  final HistoryItem item;
  const HistoryDetailScreen({super.key, required this.item});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _badgeCtrl;
  late Animation<double> _badgeScale;
  late Animation<double> _badgeFade;

  @override
  void initState() {
    super.initState();
    _badgeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _badgeScale =
        CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut);
    _badgeFade = CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeIn);
    _badgeCtrl.forward();
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    super.dispose();
  }

  // ── Cached Articles Getter ─────────────────────────────────────────────────
  List<Article> get _cachedArticles {
    final json = widget.item.matchedArticlesJson;
    if (json == null || json.isEmpty) return [];
    try {
      final List decoded = jsonDecode(json);
      return decoded
          .map((e) => Article.fromCacheJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color get _verdictColor {
    switch (widget.item.verdict) {
      case 'verified':
        return AppColors.verified;
      case 'needs_caution':
        return AppColors.caution;
      default:
        return AppColors.notVerified;
    }
  }

  String get _verdictLabel {
    switch (widget.item.verdict) {
      case 'verified':
        return 'Verified';
      case 'needs_caution':
        return 'Needs Caution';
      default:
        return 'Not Verified';
    }
  }

  String get _verdictEmoji {
    switch (widget.item.verdict) {
      case 'verified':
        return '✅';
      case 'needs_caution':
        return '⚠️';
      default:
        return '❌';
    }
  }

  String get _verdictDescription {
    switch (widget.item.verdict) {
      case 'verified':
        return 'This headline matched articles from trusted news sources.';
      case 'needs_caution':
        return 'Partial matches found. Verify with official sources before sharing.';
      default:
        return 'No matching coverage found in trusted sources. Exercise caution.';
    }
  }

  String _buildReportText() {
    final articles = _cachedArticles;
    final sb = StringBuffer();
    sb.writeln('$_verdictEmoji SachDrishti Verification Report');
    final separator = '═' * 36;
    sb.writeln(separator);
    sb.writeln();
    sb.writeln('Headline: "${widget.item.headline}"');
    sb.writeln('Verdict: $_verdictLabel');
    sb.writeln('Score: ${(widget.item.score * 100).toStringAsFixed(0)}%');
    if (widget.item.category != null) {
      sb.writeln('Category: ${widget.item.category}');
    }
    sb.writeln('Checked: ${DateFormat('MMM d, yyyy – h:mm a').format(widget.item.checkedAt)}');
    sb.writeln();

    if (articles.isNotEmpty) {
      sb.writeln('─── Matched Sources (${articles.length}) ───');
      for (final a in articles) {
        sb.writeln('  ${a.reliabilityTier.emoji} ${a.source} (${(a.matchScore * 100).toStringAsFixed(0)}%)');
        sb.writeln('    ${a.title}');
        sb.writeln('    ${a.url}');
      }
      sb.writeln();
    }

    sb.writeln('🔍 Verified using SachDrishti');
    return sb.toString();
  }

  void _share() {
    Share.share(_buildReportText());
  }

  void _export() {
    Share.share(_buildReportText());
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _buildReportText()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Report copied to clipboard ✓',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _searchOnGoogle() async {
    final q = Uri.encodeComponent(widget.item.headline);
    final uri = Uri.parse('https://www.google.com/search?q=$q+news');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _searchOnWikipedia() async {
    final q = Uri.encodeComponent(widget.item.headline);
    final uri = Uri.parse('https://en.wikipedia.org/w/index.php?search=$q');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;
    final txtSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final percent = (widget.item.score * 100).clamp(0.0, 100.0);
    final articles = _cachedArticles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Detail'),
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: _share),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Verdict badge ──────────────────────────────────────────
                  ScaleTransition(
                    scale: _badgeScale,
                    child: FadeTransition(
                      opacity: _badgeFade,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: _verdictColor.withValues(alpha: 0.08),
                          border: Border.all(
                              color: _verdictColor.withValues(alpha: 0.3),
                              width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _verdictColor.withValues(alpha: 0.15),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(_verdictEmoji,
                                style: const TextStyle(fontSize: 52)),
                            const SizedBox(height: 12),
                            Text(
                              _verdictLabel,
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _verdictColor),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                _verdictDescription,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: txtSec, fontSize: 13, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Headline card ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surfColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: divColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Extracted Headline',
                            style: TextStyle(
                                color: txtSec,
                                fontSize: 11,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          widget.item.headline,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.5),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 12, color: txtSec),
                            const SizedBox(width: 4),
                            Text(
                              'Checked ${DateFormat('MMM d, yyyy  •  h:mm a').format(widget.item.checkedAt)}',
                              style:
                                  TextStyle(fontSize: 11, color: txtSec),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Match score bar ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Match Score',
                          style: TextStyle(color: txtSec, fontSize: 13)),
                      Text('${percent.toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: _verdictColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: divColor,
                      color: _verdictColor,
                      minHeight: 8,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Sources checked pills ──────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Checked on:',
                          style: TextStyle(fontSize: 11, color: txtSec)),
                      _SourcePill(
                          label: 'Wikipedia',
                          icon: Icons.public_rounded,
                          onTap: _searchOnWikipedia),
                      _SourcePill(
                          label: 'DuckDuckGo',
                          icon: Icons.search_rounded,
                          onTap: _searchOnGoogle),
                      _SourcePill(
                          label: 'Google News',
                          icon: Icons.newspaper_rounded,
                          onTap: _searchOnGoogle),
                      _SourcePill(
                          label: 'Bing News',
                          icon: Icons.language_rounded,
                          onTap: _searchOnGoogle),
                      _SourcePill(
                          label: 'AP/Reuters',
                          icon: Icons.feed_rounded,
                          onTap: _searchOnGoogle),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Matched Sources (offline cache) ─────────────────────────
                  if (articles.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          'MATCHED SOURCES (${articles.length})',
                          style: TextStyle(
                              color: txtSec,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.verified.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.offline_pin_rounded,
                                  size: 11, color: AppColors.verified),
                              SizedBox(width: 3),
                              Text(
                                'Available offline',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.verified,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...articles.map((article) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CachedArticleCard(
                            article: article,
                            isDark: isDark,
                          ),
                        )),
                    const SizedBox(height: 16),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: divColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              size: 18, color: txtSec),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No cached articles for this verification.',
                              style: TextStyle(
                                  fontSize: 12, color: txtSec, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Section header ─────────────────────────────────────────
                  Text(
                    'SEARCH RESOURCES',
                    style: TextStyle(
                        color: txtSec,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),

                  // ── Search buttons ─────────────────────────────────────────
                  _SearchTile(
                    icon: Icons.travel_explore_rounded,
                    label: 'Search on Google News',
                    subtitle: 'Find news articles about this headline',
                    color: const Color(0xFF4285F4),
                    onTap: _searchOnGoogle,
                    surfColor: surfColor,
                    divColor: divColor,
                    txtSec: txtSec,
                  ),
                  const SizedBox(height: 10),
                  _SearchTile(
                    icon: Icons.public_rounded,
                    label: 'Search on Wikipedia',
                    subtitle: 'Find reference articles and background',
                    color: AppColors.primary,
                    onTap: _searchOnWikipedia,
                    surfColor: surfColor,
                    divColor: divColor,
                    txtSec: txtSec,
                  ),

                  const SizedBox(height: 24),

                  // ── Export & Copy buttons ───────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _export,
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          label: const Text('Export'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── News screenshot ────────────────────────────────────────
                  if (widget.item.imagePath.isNotEmpty &&
                      File(widget.item.imagePath).existsSync()) ...[
                    Text(
                      'ORIGINAL SCREENSHOT',
                      style: TextStyle(
                          color: txtSec,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(widget.item.imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────────────────────

class _CachedArticleCard extends StatelessWidget {
  final Article article;
  final bool isDark;
  const _CachedArticleCard({required this.article, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;
    final txtSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Material(
      color: surfColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final uri = Uri.tryParse(article.url);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: divColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: divColor,
                      child: Icon(Icons.article_rounded, color: txtSec),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.newspaper_rounded, size: 12, color: txtSec),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(article.source,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: txtSec)),
                        ),
                        const SizedBox(width: 4),
                        Text(article.reliabilityTier.emoji,
                            style: const TextStyle(fontSize: 10)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(article.matchScore * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    if (article.publishedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(article.publishedAt!),
                        style: TextStyle(fontSize: 10, color: txtSec),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SourcePill(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SearchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Color surfColor;
  final Color divColor;
  final Color txtSec;

  const _SearchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.surfColor,
    required this.divColor,
    required this.txtSec,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: divColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: txtSec)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 16, color: txtSec),
            ],
          ),
        ),
      ),
    );
  }
}
