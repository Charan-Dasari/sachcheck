import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sachcheck/core/router.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/providers/history_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscure = true;
  bool _keySaved = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('news_api_key') ?? '';
    if (mounted) _apiKeyController.text = key;
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('news_api_key', key);
    if (!mounted) return;
    setState(() => _keySaved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _keySaved = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'API key saved ✓',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.verified,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;
    final txtSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adjust padding for wide screens (tablets)
          final hPad = constraints.maxWidth > 600 ? constraints.maxWidth * 0.15 : 24.0;
          return ListView(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
            children: [
              const _SectionHeader('API Configuration'),
              const SizedBox(height: 12),
              // API Key Card
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
                    const Text(
                      'NewsAPI.org Key (Optional)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'App works without a key. Add a NewsAPI.org key for richer results (get one free at newsapi.org/register).',
                      style: TextStyle(color: txtSec, fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: _obscure,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Paste your API key here…',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            color: txtSec,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveApiKey,
                        icon: Icon(_keySaved ? Icons.check_rounded : Icons.save_rounded, size: 18),
                        label: Text(_keySaved ? 'Saved!' : 'Save API Key'),
                        style: _keySaved
                            ? ElevatedButton.styleFrom(backgroundColor: AppColors.verified)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const _SectionHeader('Data'),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.delete_forever_rounded,
                iconColor: AppColors.notVerified,
                title: 'Clear All History',
                subtitle: 'Remove all saved verification records',
                onTap: () => _confirmClear(context),
              ),
              const SizedBox(height: 28),
              const _SectionHeader('About'),
              const SizedBox(height: 12),
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
                    Row(
                      children: [
                        const Text('✓  ',
                            style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('SachDrishti',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const Spacer(),
                        Text('v1.0.0', style: TextStyle(color: txtSec, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'SachDrishti is a news screenshot verification assistant. It uses on-device OCR to extract headlines and cross-checks them with trusted news sources.',
                      style: TextStyle(color: txtSec, fontSize: 12, height: 1.6),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.caution.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.caution.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '⚠️  Disclaimer: SachDrishti does not guarantee the detection of fake or real news. It is a verification-assistance tool only. Always refer to official and authoritative sources.',
                        style: TextStyle(color: txtSec, fontSize: 11, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true, // detach from ShellRoute's nested navigator
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all verification history?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx, rootNavigator: true).pop();
              await ref.read(historyProvider.notifier).clearAll();
              // Use global key — safe even after dialog/navigator teardown
              scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: const Text(
                    'History cleared',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.notVerified,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.notVerified)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.textSecondary
            : AppColors.lightTextSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;
    final txtSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Material(
      color: surfColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: divColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: txtSec, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: txtSec),
            ],
          ),
        ),
      ),
    );
  }
}
