import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/services/category_tagger.dart';

/// Generates a shareable verification report card as a PNG image.
class ReportGenerator {
  /// Captures the report widget as a PNG and saves to temp directory.
  /// Returns the file path of the saved image.
  static Future<String?> generateReport({
    required String headline,
    required String verdict,
    required double score,
    required String category,
    required DateTime checkedAt,
    required List<String> sources,
  }) async {
    try {
      final widget = _ReportCardWidget(
        headline: headline,
        verdict: verdict,
        score: score,
        category: category,
        checkedAt: checkedAt,
        sources: sources,
      );

      // Use RepaintBoundary to capture the widget
      final repaintBoundary = RenderRepaintBoundary();
      final renderView = _createRenderView(widget, repaintBoundary);

      // Build the render tree
      final pipelineOwner = PipelineOwner();
      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      final image = await repaintBoundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/sachdrishti_report_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      return file.path;
    } catch (e) {
      debugPrint('ReportGenerator error: $e');
      return null;
    }
  }

  static RenderView _createRenderView(
    Widget widget,
    RenderRepaintBoundary repaintBoundary,
  ) {
    // This is a simplified approach — we build the widget off-screen
    final renderView = RenderView(
      view: ui.PlatformDispatcher.instance.views.first,
    );

    final renderObject = RenderPositionedBox(
      alignment: Alignment.center,
      child: repaintBoundary,
    );
    renderView.child = renderObject;

    return renderView;
  }
}

/// The actual report card widget that gets rendered to an image.
/// This is used only for rendering, not displayed in the app directly.
class _ReportCardWidget extends StatelessWidget {
  final String headline;
  final String verdict;
  final double score;
  final String category;
  final DateTime checkedAt;
  final List<String> sources;

  const _ReportCardWidget({
    required this.headline,
    required this.verdict,
    required this.score,
    required this.category,
    required this.checkedAt,
    required this.sources,
  });

  Color get _verdictColor {
    switch (verdict) {
      case 'verified':
        return AppColors.verified;
      case 'needs_caution':
        return AppColors.caution;
      default:
        return AppColors.notVerified;
    }
  }

  String get _verdictLabel {
    switch (verdict) {
      case 'verified':
        return 'Verified ✅';
      case 'needs_caution':
        return 'Needs Caution ⚠️';
      default:
        return 'Not Verified ❌';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _verdictColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('📰', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Text('SachDrishti',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${CategoryTagger.icon(category)} $category',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),

          // Verdict badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _verdictColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _verdictColor.withValues(alpha: 0.4)),
            ),
            child: Text(_verdictLabel,
                style: TextStyle(
                    color: _verdictColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
          const SizedBox(height: 14),

          // Headline
          Text(headline,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.5)),
          const SizedBox(height: 14),

          // Score bar
          Row(
            children: [
              Text('Match Score: ${(score * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: Colors.white12,
              color: _verdictColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Sources
          if (sources.isNotEmpty) ...[
            Text('Sources: ${sources.join(', ')}',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 8),
          ],

          // Footer
          const Divider(color: Colors.white12),
          const Text('Verified using SachDrishti • News Verification App',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}
