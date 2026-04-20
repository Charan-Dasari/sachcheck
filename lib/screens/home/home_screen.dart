import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/main.dart' show pendingShareImagePath;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});


  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pulseController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Check if an image was shared from another app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pendingShareImagePath != null) {
        final path = pendingShareImagePath!;
        pendingShareImagePath = null;
        context.push('/processing', extra: path);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null || !mounted) return;
    context.push('/processing', extra: picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtSec =
    isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final hPad = isTablet ? constraints.maxWidth * 0.12 : 24.0;
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── App bar logo ──────────────────────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/SachDristhi_2.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          color: isDark ? null : AppColors.primary,
                        ),
                      ),
                      // ─────────────────────────────────────────────────────
                      const SizedBox(width: 0),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ).createShader(b),
                        child: const Text(
                          'SachDrishti',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                    EdgeInsets.symmetric(horizontal: hPad, vertical: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        _buildHeroSection(isTablet),
                        const SizedBox(height: 36),
                        Text(
                          'How would you like to verify?',
                          style: TextStyle(
                            color: txtSec,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.camera_alt_rounded,
                                label: 'Camera',
                                subtitle: 'Take a photo',
                                onTap: () => _pickImage(ImageSource.camera),
                                gradient: const [
                                  Color(0xFF6C63FF),
                                  Color(0xFF9C8FFF),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.photo_library_rounded,
                                label: 'Gallery',
                                subtitle: 'Pick screenshot',
                                onTap: () => _pickImage(ImageSource.gallery),
                                gradient: const [
                                  Color(0xFF00B4D8),
                                  Color(0xFF00D4FF),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ── Text-Only Verification ────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: _ActionCard(
                            icon: Icons.edit_note_rounded,
                            label: 'Type a Headline',
                            subtitle: 'Verify without a screenshot',
                            onTap: () => context.push('/editor', extra: {
                              'imagePath': '',
                              'headline': '',
                              'rawText': '',
                            }),
                            gradient: const [
                              Color(0xFF10B981),
                              Color(0xFF34D399),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                        _buildDisclaimerCard(isDark),
                        const SizedBox(height: 24),
                        _buildVerdictLegend(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isTablet) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) =>
          Transform.scale(scale: _pulseAnim.value, child: child),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? 40 : 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.accent.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text('📰', style: TextStyle(fontSize: isTablet ? 72 : 52)),
            SizedBox(height: isTablet ? 20 : 14),
            Text(
              'Verify News\nScreenshot',
              style: TextStyle(
                fontSize: isTablet ? 34 : 26,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Multi-language OCR • Cross-source verified • Privacy-first',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.caution.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.caution.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'SachDrishti assists verification — it does not guarantee fake or real news. Always cross-check with official sources.',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdictLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verdict Guide',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        const _LegendRow(
          color: AppColors.verified,
          emoji: '✅',
          label: 'Verified',
          description: 'Matches trusted sources',
        ),
        const _LegendRow(
          color: AppColors.caution,
          emoji: '⚠️',
          label: 'Needs Caution',
          description: 'Partial match found',
        ),
        const _LegendRow(
          color: AppColors.notVerified,
          emoji: '❌',
          label: 'Not Verified',
          description: 'No coverage in trusted news',
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final List<Color> gradient;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.gradient,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: widget.gradient
                  .map((c) => c.withValues(alpha: 0.15))
                  .toList(),
            ),
            border: Border.all(
              color: widget.gradient.first.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: widget.gradient),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String emoji;
  final String label;
  final String description;

  const _LegendRow({
    required this.color,
    required this.emoji,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$emoji  $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '· $description',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}