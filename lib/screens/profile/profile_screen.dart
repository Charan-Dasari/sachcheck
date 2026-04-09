import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.lightBackground;
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final txtPrimary =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final txtSec =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;

    final user = FirebaseAuth.instance.currentUser;
    final profileAsync = ref.watch(userProfileStreamProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, s) => Center(
            child: Text('Error: $e', style: TextStyle(color: txtSec))),
        data: (profile) {
          if (profile == null || user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Not signed in', style: TextStyle(color: txtSec)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            );
          }

          final displayName =
              profile['displayName'] ?? user.displayName ?? 'User';
          final email = profile['email'] ?? user.email ?? '';
          final totalV = (profile['totalVerifications'] ?? 0) as int;
          final verified = (profile['verifiedCount'] ?? 0) as int;
          final caution = (profile['cautionCount'] ?? 0) as int;
          final notVerified = (profile['notVerifiedCount'] ?? 0) as int;

          // Credibility score: weighted percentage
          final credScore = totalV > 0
              ? ((verified * 1.0 + caution * 0.5) / totalV * 100).round()
              : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ── Avatar & Name ──────────────────────────────────────
                CircleAvatar(
                  radius: 44,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(displayName,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: txtPrimary)),
                const SizedBox(height: 4),
                Text(email,
                    style: TextStyle(fontSize: 13, color: txtSec)),
                const SizedBox(height: 28),

                // ── Credibility Score ──────────────────────────────────
                _CredibilityScoreCard(
                  score: credScore,
                  totalVerifications: totalV,
                  surfColor: surfColor,
                  txtPrimary: txtPrimary,
                  txtSec: txtSec,
                  divColor: divColor,
                ),
                const SizedBox(height: 20),

                // ── Stats Grid ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total',
                        value: '$totalV',
                        icon: Icons.fact_check_rounded,
                        color: AppColors.primary,
                        surfColor: surfColor,
                        txtPrimary: txtPrimary,
                        txtSec: txtSec,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Verified',
                        value: '$verified',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.verified,
                        surfColor: surfColor,
                        txtPrimary: txtPrimary,
                        txtSec: txtSec,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Caution',
                        value: '$caution',
                        icon: Icons.warning_rounded,
                        color: AppColors.caution,
                        surfColor: surfColor,
                        txtPrimary: txtPrimary,
                        txtSec: txtSec,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Not Verified',
                        value: '$notVerified',
                        icon: Icons.cancel_rounded,
                        color: AppColors.notVerified,
                        surfColor: surfColor,
                        txtPrimary: txtPrimary,
                        txtSec: txtSec,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Settings Section ───────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: surfColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: divColor),
                  ),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.key_rounded,
                        label: 'API Key Settings',
                        txtPrimary: txtPrimary,
                        txtSec: txtSec,
                        onTap: () => context.push('/settings'),
                      ),
                      Divider(height: 1, color: divColor),
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        label: 'About SachDrishti',
                        txtPrimary: txtPrimary,
                        txtSec: txtSec,
                        onTap: () => _showAbout(context, isDark, surfColor),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Sign Out ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.notVerified),
                    label: const Text('Sign Out',
                        style: TextStyle(
                            color: AppColors.notVerified,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color:
                              AppColors.notVerified.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAbout(BuildContext context, bool isDark, Color surfColor) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: surfColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About SachDrishti'),
        content: const Text(
          'SachDrishti is a privacy-first news verification assistant. '
          'It uses on-device OCR to extract headlines and cross-checks '
          'them with trusted news sources.\n\n'
          'Version 1.0.0',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ── Credibility Score Card ─────────────────────────────────────────────────
class _CredibilityScoreCard extends StatelessWidget {
  final int score;
  final int totalVerifications;
  final Color surfColor;
  final Color txtPrimary;
  final Color txtSec;
  final Color divColor;

  const _CredibilityScoreCard({
    required this.score,
    required this.totalVerifications,
    required this.surfColor,
    required this.txtPrimary,
    required this.txtSec,
    required this.divColor,
  });

  Color get _scoreColor {
    if (score >= 70) return AppColors.verified;
    if (score >= 40) return AppColors.caution;
    return AppColors.notVerified;
  }

  String get _scoreLabel {
    if (totalVerifications == 0) return 'No data yet';
    if (score >= 70) return 'Excellent';
    if (score >= 40) return 'Moderate';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _scoreColor.withValues(alpha: 0.08),
            surfColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Circular score indicator
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: totalVerifications > 0 ? score / 100 : 0,
                    strokeWidth: 6,
                    backgroundColor: _scoreColor.withValues(alpha: 0.15),
                    color: _scoreColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  totalVerifications > 0 ? '$score' : '—',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _scoreColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Credibility Score',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: txtPrimary)),
                const SizedBox(height: 4),
                Text(_scoreLabel,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _scoreColor)),
                const SizedBox(height: 4),
                Text(
                  totalVerifications > 0
                      ? 'Based on $totalVerifications verifications'
                      : 'Verify news to build your score',
                  style: TextStyle(fontSize: 11, color: txtSec),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color surfColor;
  final Color txtPrimary;
  final Color txtSec;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.surfColor,
    required this.txtPrimary,
    required this.txtSec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: txtPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 12, color: txtSec)),
        ],
      ),
    );
  }
}

// ── Settings Tile ──────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color txtPrimary;
  final Color txtSec;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.txtPrimary,
    required this.txtSec,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: txtPrimary)),
      trailing: Icon(Icons.chevron_right_rounded, color: txtSec, size: 20),
      onTap: onTap,
    );
  }
}
