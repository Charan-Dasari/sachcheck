import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/models/verification_result.dart';
import 'package:sachcheck/providers/auth_provider.dart';
import 'package:sachcheck/providers/history_provider.dart';
import 'package:sachcheck/services/category_tagger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final VerificationResult result;
  const ResultScreen({super.key, required this.result});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _badgeCtrl;
  late AnimationController _listCtrl;
  late Animation<double> _badgeScale;
  late Animation<double> _badgeFade;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _badgeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _badgeScale =
        CurvedAnimation(parent: _badgeCtrl, curve: Curves.elasticOut);
    _badgeFade = CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeIn);
    _badgeCtrl.forward().then((_) => _listCtrl.forward());
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Color get _verdictColor {
    switch (widget.result.verdict) {
      case Verdict.verified:
        return AppColors.verified;
      case Verdict.needsCaution:
        return AppColors.caution;
      case Verdict.notVerified:
        return AppColors.notVerified;
    }
  }

  Color get _confidenceColor {
    switch (widget.result.confidenceLevel) {
      case 'High':
        return AppColors.verified;
      case 'Medium':
        return AppColors.caution;
      default:
        return AppColors.notVerified;
    }
  }

  void _share() {
    final v = widget.result.verdict;
    Share.share(
      '${v.emoji} SachDrishti Result: ${v.label}\n\n'
      '"${widget.result.headline}"\n\n'
      'Score: ${(widget.result.topScore * 100).toStringAsFixed(0)}%\n'
      'Checked on: ${DateFormat('MMM d, yyyy – h:mm a').format(widget.result.checkedAt)}\n\n'
      'Verified using SachDrishti',
    );
  }

  String _buildExportReport(VerificationResult r) {
    final sb = StringBuffer();
    sb.writeln('${r.verdict.emoji} SachDrishti Verification Report');
    final separator = '═' * 36;
    sb.writeln(separator);
    sb.writeln();
    sb.writeln('Headline: "${r.headline}"');
    sb.writeln('Verdict: ${r.verdict.label}');
    sb.writeln('Score: ${(r.topScore * 100).toStringAsFixed(0)}%');
    sb.writeln('Confidence: ${r.confidenceLevel}');
    sb.writeln('Category: ${r.category}');
    sb.writeln('Checked: ${DateFormat('MMM d, yyyy – h:mm a').format(r.checkedAt)}');
    sb.writeln();

    if (r.flags.isNotEmpty) {
      sb.writeln('─── Flags ───');
      for (final flag in r.flags) {
        sb.writeln('  ⚠ ${flag.replaceAll('⚠ ', '')}');
      }
      sb.writeln();
    }

    if (r.matchedArticles.isNotEmpty) {
      sb.writeln('─── Matched Sources (${r.matchedArticles.length}) ───');
      for (final a in r.matchedArticles) {
        sb.writeln('  ${a.reliabilityTier.emoji} [${a.reliabilityTier.label}] ${a.source} (${(a.matchScore * 100).toStringAsFixed(0)}%)');
        sb.writeln('    ${a.title}');
        sb.writeln('    ${a.url}');
      }
      sb.writeln();
    }

    sb.writeln('🔍 Verified using SachDrishti');
    return sb.toString();
  }

  Future<void> _saveToHistory() async {
    await ref.read(historyProvider.notifier).addResult(widget.result);

    // Update Firestore stats
    try {
      await ref
          .read(authServiceProvider)
          .updateVerificationStats(widget.result.verdict.storageKey);
    } catch (_) {
      // Non-critical — don't block on Firestore failure
    }

    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Saved to history ✓',
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

  Future<void> _shareToChat(VerificationResult r) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to share to ChatRoom')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('messages').add({
      'text': r.headline,
      'userId': user.uid,
      'userName': user.displayName ?? 'User',
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'verification_share',
      'verificationData': {
        'headline': r.headline,
        'verdict': r.verdict.storageKey,
        'score': r.topScore,
      },
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Shared to ChatRoom ✓',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;
    final txtSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.share_rounded), onPressed: _share),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final hPad = constraints.maxWidth > 600
              ? constraints.maxWidth * 0.12
              : 24.0;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildVerdictBadge(),
                      const SizedBox(height: 12),
                      // Category tag
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${CategoryTagger.icon(r.category)} ${r.category}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildHeadlineCard(surfColor, divColor, txtSec),
                      const SizedBox(height: 12),
                      // ── Warning flags ──────────────────
                      if (r.flags.isNotEmpty)
                        ...r.flags.map((flag) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.caution.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.caution.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    size: 16, color: AppColors.caution),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    flag.replaceAll('⚠ ', ''),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.caution,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      const SizedBox(height: 8),
                      _buildScoreBar(txtSec),
                      const SizedBox(height: 12),
                      _buildSourcesRow(txtSec),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
              if (r.matchedArticles.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Text(
                      'Matched Sources (${r.matchedArticles.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              if (r.matchedArticles.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _buildManualSearchButton(),
                  ),
                ),
              if (r.matchedArticles.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return AnimatedBuilder(
                      animation: _listCtrl,
                      builder: (_, child) {
                        final delay = index * 0.2;
                        final animValue =
                            (((_listCtrl.value - delay) / (1 - delay))
                                .clamp(0.0, 1.0));
                        return Opacity(
                          opacity: animValue,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - animValue)),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: hPad, vertical: 6),
                        child: _ArticleCard(
                          article: r.matchedArticles[index],
                          isDark: isDark,
                        ),
                      ),
                    );
                  },
                  childCount: r.matchedArticles.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 24),
                  child: Column(
                    children: [
                      if (!_saved)
                        ElevatedButton.icon(
                          onPressed: _saveToHistory,
                          icon: const Icon(Icons.bookmark_add_rounded),
                          label: const Text('Save to History'),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_rounded,
                              color: AppColors.verified),
                          label: const Text('Saved ✓',
                              style: TextStyle(color: AppColors.verified)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: const BorderSide(color: AppColors.verified),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // ── Export, Copy & Share buttons ───────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final report = _buildExportReport(r);
                                Share.share(report);
                              },
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
                              onPressed: () {
                                final report = _buildExportReport(r);
                                Clipboard.setData(ClipboardData(text: report));
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
                              },
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('Copy'),
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
                              onPressed: () => _shareToChat(r),
                              icon: const Icon(Icons.chat_rounded, size: 18),
                              label: const Text('Chat'),
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
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text('Verify Another',
                            style: TextStyle(color: txtSec)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVerdictBadge() {
    return ScaleTransition(
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
                color: _verdictColor.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                  color: _verdictColor.withValues(alpha: 0.18),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Text(widget.result.verdict.emoji,
                  style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                widget.result.verdict.label,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _verdictColor),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.result.verdict.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 13,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeadlineCard(Color surf, Color div, Color txtSec) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: div),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Extracted Headline',
              style: TextStyle(
                  color: txtSec, fontSize: 11, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(
            widget.result.headline,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesRow(Color txtSec) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Checked on:',
            style: TextStyle(fontSize: 11, color: txtSec)),
        const _SourcePill(label: 'Wikipedia', icon: Icons.public_rounded),
        const _SourcePill(label: 'DuckDuckGo', icon: Icons.search_rounded),
        const _SourcePill(label: 'Google News', icon: Icons.newspaper_rounded),
        const _SourcePill(label: 'Bing News', icon: Icons.language_rounded),
        const _SourcePill(label: 'AP/Reuters', icon: Icons.feed_rounded),
        const _SourcePill(label: 'NDTV', icon: Icons.tv_rounded),
        const _SourcePill(label: 'Hindustan Times', icon: Icons.article_rounded),
        const _SourcePill(label: 'India Today', icon: Icons.newspaper_rounded),
        const _SourcePill(label: 'Times of India', icon: Icons.article_outlined),
        if (widget.result.matchedArticles
            .any((a) => a.source != 'Wikipedia' && a.source != 'DuckDuckGo' &&
                a.source != 'Google News' && a.source != 'Bing News' &&
                a.source != 'AP/Reuters' && a.source != 'NDTV' &&
                a.source != 'Hindustan Times' && a.source != 'India Today' &&
                a.source != 'Times of India'))
          const _SourcePill(label: 'NewsAPI', icon: Icons.rss_feed_rounded),
      ],
    );
  }

  Widget _buildManualSearchButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        final q = Uri.encodeComponent(widget.result.headline);
        final uri = Uri.parse('https://www.google.com/search?q=$q+news');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      icon: const Icon(Icons.open_in_browser_rounded, size: 18),
      label: const Text('Search manually on Google'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildScoreBar(Color txtSec) {
    final percent = (widget.result.topScore * 100).clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Match Score',
                    style: TextStyle(color: txtSec, fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _confidenceColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.result.confidenceLevel} confidence',
                    style: TextStyle(
                      fontSize: 10,
                      color: _confidenceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.divider
                : AppColors.lightDivider,
            color: _verdictColor,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _SourcePill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SourcePill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final bool isDark;
  const _ArticleCard({required this.article, required this.isDark});

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
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
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
