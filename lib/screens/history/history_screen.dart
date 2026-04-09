import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/models/history_item.dart';
import 'package:sachcheck/providers/history_provider.dart';
import 'package:sachcheck/services/category_tagger.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  String _verdictFilter = 'all'; // all, verified, needs_caution, not_verified
  String _categoryFilter = 'all';

  Color _verdictColor(String verdict) {
    switch (verdict) {
      case 'verified':
        return AppColors.verified;
      case 'needs_caution':
        return AppColors.caution;
      default:
        return AppColors.notVerified;
    }
  }

  String _verdictLabel(String verdict) {
    switch (verdict) {
      case 'verified':
        return 'Verified ✅';
      case 'needs_caution':
        return 'Needs Caution ⚠️';
      default:
        return 'Not Verified ❌';
    }
  }

  List<HistoryItem> _filterItems(List<HistoryItem> items) {
    return items.where((item) {
      // Verdict filter
      if (_verdictFilter != 'all' && item.verdict != _verdictFilter) {
        return false;
      }
      // Category filter
      if (_categoryFilter != 'all' && (item.category ?? 'General') != _categoryFilter) {
        return false;
      }
      // Search query
      if (_searchQuery.isNotEmpty) {
        final lower = _searchQuery.toLowerCase();
        return item.headline.toLowerCase().contains(lower);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final filtered = _filterItems(history);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;
    final txtSec =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    // Distinct categories from history
    final categories = history
        .map((e) => e.category ?? 'General')
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: AppColors.notVerified),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search headlines…',
                hintStyle: TextStyle(color: txtSec, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: txtSec, size: 20),
                filled: true,
                fillColor: surfColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: divColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: divColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── Verdict filter chips ─────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _verdictFilter == 'all',
                  onTap: () => setState(() => _verdictFilter = 'all'),
                ),
                _FilterChip(
                  label: '✅ Verified',
                  isSelected: _verdictFilter == 'verified',
                  onTap: () => setState(() => _verdictFilter = 'verified'),
                  color: AppColors.verified,
                ),
                _FilterChip(
                  label: '⚠️ Caution',
                  isSelected: _verdictFilter == 'needs_caution',
                  onTap: () =>
                      setState(() => _verdictFilter = 'needs_caution'),
                  color: AppColors.caution,
                ),
                _FilterChip(
                  label: '❌ Not Verified',
                  isSelected: _verdictFilter == 'not_verified',
                  onTap: () =>
                      setState(() => _verdictFilter = 'not_verified'),
                  color: AppColors.notVerified,
                ),
                const SizedBox(width: 8),
                // Category chips
                ...categories.map((cat) => _FilterChip(
                      label: '${CategoryTagger.icon(cat)} $cat',
                      isSelected: _categoryFilter == cat,
                      onTap: () => setState(() {
                        _categoryFilter =
                            _categoryFilter == cat ? 'all' : cat;
                      }),
                    )),
              ],
            ),
          ),

          // ── Results count ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: txtSec),
              ),
            ),
          ),

          // ── History list ─────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          history.isEmpty
                              ? 'No verifications yet'
                              : 'No results match your filter',
                          style: TextStyle(
                              color: txtSec,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          history.isEmpty
                              ? 'Verify a screenshot to get started'
                              : 'Try a different search or filter',
                          style: TextStyle(color: txtSec, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _HistoryCard(
                        item: item,
                        verdictColor: _verdictColor(item.verdict),
                        verdictLabel: _verdictLabel(item.verdict),
                        isDark: isDark,
                        onTap: () =>
                            context.push('/history-detail', extra: item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear History'),
        content: const Text(
            'This will permanently delete all saved verifications. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.notVerified,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip ────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppColors.primary).withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (color ?? AppColors.primary)
                  : Theme.of(context).brightness == Brightness.dark
                      ? AppColors.divider
                      : AppColors.lightDivider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (color ?? AppColors.primary)
                  : Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── History Card ───────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final Color verdictColor;
  final String verdictLabel;
  final bool isDark;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.item,
    required this.verdictColor,
    required this.verdictLabel,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;
    final txtSec =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: surfColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divColor),
            ),
            child: Row(
              children: [
                // Verdict indicator
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: verdictColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: verdictColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(verdictLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: verdictColor)),
                          ),
                          if (item.category != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${CategoryTagger.icon(item.category!)} ${item.category}',
                              style: TextStyle(fontSize: 10, color: txtSec),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            DateFormat('MMM d, h:mm a')
                                .format(item.checkedAt),
                            style: TextStyle(fontSize: 10, color: txtSec),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: txtSec, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
