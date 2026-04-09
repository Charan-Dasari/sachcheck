import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/providers/verification_provider.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const ProcessingScreen({super.key, required this.imagePath});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationCtrl;
  late AnimationController _pulseCtrl;
  bool _dialogShown = false;
  String _statusMessage = 'Scanning image for text…';

  @override
  void initState() {
    super.initState();
    _rotationCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runOcr());
  }

  /// Runs OCR only and then navigates to the headline editor.
  Future<void> _runOcr() async {
    final ocr = ref.read(ocrServiceProvider);

    try {
      setState(() => _statusMessage = 'Scanning image for text…');
      final ocrResult = await ocr.extractWithHeadline(widget.imagePath);

      if (!mounted) return;

      // Validate that we got usable content
      if (!ocrResult.isUsable) {
        if (!_dialogShown) {
          _dialogShown = true;
          await _showInvalidImageDialog(ocrResult.userMessage);
          if (mounted) context.pop();
        }
        return;
      }

      setState(() => _statusMessage = 'Text extracted! Opening editor…');
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      // Navigate to the headline editor with the extracted data
      context.pushReplacement('/editor', extra: {
        'imagePath': widget.imagePath,
        'headline': ocrResult.headline.isNotEmpty
            ? ocrResult.headline
            : ocrResult.rawText,
        'rawText': ocrResult.rawText,
      });
    } catch (e) {
      if (mounted) context.pop();
    }
  }

  Future<void> _showInvalidImageDialog(String message) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final txtPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final txtSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('📷', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cannot Read Image',
                style: TextStyle(
                    color: txtPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: txtSec, fontSize: 13, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Try Another Image'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.background : AppColors.lightBackground;
    final txtPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final txtSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final screenH = MediaQuery.of(context).size.height;
    final imageHeight = (screenH * 0.32).clamp(200.0, 320.0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary
                            .withValues(alpha: 0.3 + 0.2 * _pulseCtrl.value),
                        bgColor,
                      ],
                    ),
                  ),
                  child: RotationTransition(
                    turns: _rotationCtrl,
                    child: const Icon(Icons.autorenew_rounded,
                        color: AppColors.primary, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: txtPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Processing on-device. Your image is never uploaded.',
                style: TextStyle(fontSize: 12, color: txtSec),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _StepIndicator(statusMessage: _statusMessage),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final String statusMessage;
  const _StepIndicator({required this.statusMessage});

  int get _step {
    if (statusMessage.contains('editor') || statusMessage.contains('Editor')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txtSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(active: true, done: true, label: 'Scan', txtSec: txtSec, divColor: divColor),
        _Line(done: _step >= 1, divColor: divColor),
        _Dot(active: _step >= 1, done: _step >= 1, label: 'Edit', txtSec: txtSec, divColor: divColor),
        _Line(done: false, divColor: divColor),
        _Dot(active: false, done: false, label: 'Verify', txtSec: txtSec, divColor: divColor),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final bool done;
  final String label;
  final Color txtSec;
  final Color divColor;
  const _Dot({required this.active, required this.done, required this.label, required this.txtSec, required this.divColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary : divColor,
          ),
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: active ? AppColors.primary : txtSec)),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final bool done;
  final Color divColor;
  const _Line({required this.done, required this.divColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: 48,
        height: 2,
        color: done ? AppColors.primary : divColor,
      ),
    );
  }
}
