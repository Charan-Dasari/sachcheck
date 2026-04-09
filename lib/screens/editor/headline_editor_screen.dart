import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/providers/verification_provider.dart';
import 'package:sachcheck/screens/scanner/text_scanner_screen.dart';

/// Shows the OCR-extracted headline in an editable field so the user can
/// review / correct the text before verification runs.
/// Also supports text-only mode (no image) for direct headline verification.
class HeadlineEditorScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final String extractedHeadline;
  final String rawText;

  const HeadlineEditorScreen({
    super.key,
    required this.imagePath,
    required this.extractedHeadline,
    required this.rawText,
  });

  @override
  ConsumerState<HeadlineEditorScreen> createState() =>
      _HeadlineEditorScreenState();
}

class _HeadlineEditorScreenState extends ConsumerState<HeadlineEditorScreen> {
  late TextEditingController _headlineCtrl;
  bool _isVerifying = false;

  bool get _isTextOnly => widget.imagePath.isEmpty;

  @override
  void initState() {
    super.initState();
    _headlineCtrl = TextEditingController(text: widget.extractedHeadline);
  }

  @override
  void dispose() {
    _headlineCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final headline = _headlineCtrl.text.trim();
    if (headline.isEmpty) return;
    setState(() => _isVerifying = true);

    final result =
        await ref.read(verificationProvider.notifier).verifyWithHeadline(
              imagePath: widget.imagePath,
              headline: headline,
              rawText: widget.rawText.isNotEmpty ? widget.rawText : headline,
            );

    if (!mounted) return;

    if (result != null) {
      context.pushReplacement('/result', extra: result);
    } else {
      setState(() => _isVerifying = false);
      final state = ref.read(verificationProvider);
      if (state is VerificationInvalidImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      }
    }
  }

  Future<void> _openScanner() async {
    final selectedText = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => TextScannerScreen(imagePath: widget.imagePath),
      ),
    );
    if (selectedText != null && selectedText.isNotEmpty && mounted) {
      setState(() {
        _headlineCtrl.text = selectedText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final divColor = isDark ? AppColors.divider : AppColors.lightDivider;
    final txtSec =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final imageHeight = MediaQuery.of(context).size.height * 0.28;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isTextOnly ? 'Type & Verify' : 'Review & Edit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image thumbnail (hidden in text-only mode) ──────────────
            if (!_isTextOnly) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: imageHeight.clamp(160.0, 260.0),
                      width: double.infinity,
                      child: Image.file(File(widget.imagePath),
                          fit: BoxFit.cover),
                    ),
                  ),
                  // Scan Text button overlay
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: InkWell(
                      onTap: _openScanner,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.document_scanner_rounded,
                                color: AppColors.primary, size: 18),
                            SizedBox(width: 6),
                            Text('Scan Text',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ── Info text ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isTextOnly ? Icons.edit_rounded : Icons.edit_note_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isTextOnly
                          ? 'Type or paste a news headline below to verify it against trusted sources.'
                          : 'Review the extracted text below. Tap "Scan Text" on the image to select specific text, or edit manually.',
                      style: TextStyle(
                          color: txtSec, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Section label ────────────────────────────────────────────
            Text(
              'HEADLINE TO VERIFY',
              style: TextStyle(
                color: txtSec,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            // ── Editable headline ────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: surfColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: divColor),
              ),
              child: TextField(
                controller: _headlineCtrl,
                maxLines: 4,
                minLines: 2,
                autofocus: _isTextOnly,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, height: 1.5),
                decoration: InputDecoration(
                  hintText: _isTextOnly
                      ? 'Paste or type a news headline…'
                      : 'Enter or edit headline text…',
                  hintStyle: TextStyle(color: txtSec, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Verify button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isVerifying ? null : _verify,
                icon: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_rounded, size: 20),
                label: Text(_isVerifying ? 'Verifying…' : 'Verify This'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text('Cancel', style: TextStyle(color: txtSec)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
