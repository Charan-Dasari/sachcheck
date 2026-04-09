import 'dart:ui' show Rect;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Returns the full raw text extracted from the image.
  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);
    await _recognizer.close();
    return recognized.text;
  }

  /// Extracts the most likely headline from raw OCR text using block structure.
  /// 
  /// Now runs multiple script recognizers (Latin, Devanagari, Chinese, Korean,
  /// Japanese) in parallel and picks the one with the most text output.
  ///
  /// Strategy:
  /// 1. Process image with all recognizers and pick the best result
  /// 2. Identify text blocks with bounding boxes
  /// 3. Score each block by area (larger block = more prominent = likely headline)
  /// 4. Prefer blocks near the top of the image (headlines appear early)
  /// 5. Filter out very short strings (metadata, timestamps, usernames)
  Future<OcrResult> extractWithHeadline(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    // Run multiple script recognizers in parallel for multi-language support
    final recognizers = <TextRecognitionScript, TextRecognizer>{
      TextRecognitionScript.latin: TextRecognizer(script: TextRecognitionScript.latin),
      TextRecognitionScript.devanagiri: TextRecognizer(script: TextRecognitionScript.devanagiri),
      TextRecognitionScript.chinese: TextRecognizer(script: TextRecognitionScript.chinese),
      TextRecognitionScript.korean: TextRecognizer(script: TextRecognitionScript.korean),
      TextRecognitionScript.japanese: TextRecognizer(script: TextRecognitionScript.japanese),
    };

    try {
      // Process all recognizers in parallel
      final futures = recognizers.entries.map((entry) async {
        try {
          final result = await entry.value.processImage(inputImage);
          return MapEntry(entry.key, result);
        } catch (_) {
          return MapEntry(entry.key, null);
        }
      });

      final results = await Future.wait(futures);

      // Pick the recognizer that produced the most text
      RecognizedText? bestResult;
      int bestLength = 0;

      for (final entry in results) {
        final result = entry.value;
        if (result != null && result.text.trim().length > bestLength) {
          bestLength = result.text.trim().length;
          bestResult = result;
        }
      }

      if (bestResult == null || bestResult.text.trim().isEmpty) {
        return const OcrResult(rawText: '', headline: '', confidence: OcrConfidence.noText);
      }

      final rawText = bestResult.text.trim();

      // --- Confidence check: minimum word count ---
      final words = rawText.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
      if (words.length < 4) {
        return OcrResult(rawText: rawText, headline: '', confidence: OcrConfidence.tooShort);
      }

      // --- Check if content looks like a news screenshot ---
      final confidence = _assessConfidence(rawText, bestResult.blocks);
      if (confidence == OcrConfidence.irrelevant) {
        return OcrResult(rawText: rawText, headline: '', confidence: OcrConfidence.irrelevant);
      }

      // --- Headline extraction using block area + position scoring ---
      final headline = _extractHeadlineFromBlocks(bestResult.blocks, rawText);

      return OcrResult(rawText: rawText, headline: headline, confidence: confidence);
    } finally {
      // Close all recognizers
      for (final recognizer in recognizers.values) {
        await recognizer.close();
      }
    }
  }

  /// Returns all text blocks with bounding boxes for the scanner overlay.
  Future<OcrScanResult> extractAllBlocks(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(inputImage);

      final blocks = <OcrTextBlock>[];
      double maxRight = 0;
      double maxBottom = 0;

      for (final block in recognized.blocks) {
        final bb = block.boundingBox;
        if (bb.right > maxRight) maxRight = bb.right;
        if (bb.bottom > maxBottom) maxBottom = bb.bottom;

        final lines = block.lines.map((l) => l.text).toList();
        blocks.add(OcrTextBlock(
          text: block.text,
          rect: bb,
          lines: lines,
        ));
      }

      return OcrScanResult(
        blocks: blocks,
        imageWidth: maxRight > 0 ? maxRight : 1000,
        imageHeight: maxBottom > 0 ? maxBottom : 1500,
        fullText: recognized.text,
      );
    } finally {
      await recognizer.close();
    }
  }

  // ── Known newspaper / channel mastheads to skip ──────────────────────────
  static final _mastheadPattern = RegExp(
    r'^(the\s+)?(times of india|hindustan times|the hindu|indian express|'
    r'economic times|navbharat times|dainik bhaskar|dainik jagran|'
    r'amar ujala|deccan herald|new indian express|financial express|'
    r'business standard|mint|livemint|ndtv|aaj tak|zee news|'
    r'india today|republic|republic bharat|news18|tv9|'
    r'bbc|cnn|reuters|associated press|ap news|'
    r'times now|mirror now|the wire|scroll|the print|'
    r'opinion|editorial|breaking news|exclusive)[:\s]*$',
    caseSensitive: false,
  );

  bool _isMasthead(String text) {
    final trimmed = text.trim();
    // Exact masthead match
    if (_mastheadPattern.hasMatch(trimmed)) return true;
    // All-caps, ≤ 5 words and NO verb-like structure → likely a logo/brand
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length <= 5 &&
        trimmed == trimmed.toUpperCase() &&
        !trimmed.contains(RegExp(r'[.!?]'))) {
      return true;
    }
    return false;
  }

  /// Scores blocks by area × position weight to find the most prominent text.
  String _extractHeadlineFromBlocks(List<TextBlock> blocks, String rawText) {
    if (blocks.isEmpty) return _extractHeadlineFallback(rawText);

    // Find image height estimate from blocks
    double maxBottom = 0;
    for (final block in blocks) {
      final bottom = block.boundingBox.bottom;
      if (bottom > maxBottom) maxBottom = bottom;
    }
    if (maxBottom == 0) maxBottom = 1000;

    // Only blocks with meaningful text (≥ 3 words, ≥ 15 chars, not a masthead)
    final candidates = <_BlockScore>[];
    for (final block in blocks) {
      final text = _cleanBlockText(block.text);
      if (text.length < 15) continue;
      final wordCount = text.split(RegExp(r'\s+')).where((w) => w.length > 1).length;
      if (wordCount < 3) continue;
      // Skip newspaper mastheads / logo text
      if (_isMasthead(text)) continue;

      final bb = block.boundingBox;
      final area = (bb.width * bb.height).toDouble();
      // Prefer blocks in top 60% of image (headlines are usually near top)
      final relativeTop = maxBottom > 0 ? bb.top / maxBottom : 0.0;
      final topWeight = relativeTop < 0.6 ? (1.0 - relativeTop * 0.5) : 0.6;
      candidates.add(_BlockScore(text: text, score: area * topWeight));
    }

    if (candidates.isEmpty) return _extractHeadlineFallback(rawText);

    // Sort by score descending
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final best = candidates.first.text;
    return best.length > 200 ? '${best.substring(0, 200)}…' : best;
  }

  String _cleanBlockText(String text) {
    return text
        .replaceAll(RegExp(r'[@#][\w.]+'), '') // remove @handles #hashtags
        .replaceAll(RegExp(r'https?://\S+'), '') // remove URLs
        .replaceAll(RegExp(r'\d{1,2}:\d{2}\s*(AM|PM)?', caseSensitive: false), '') // remove timestamps
        .replaceAll(RegExp(r'^\s*[\d,]+\s*(likes?|comments?|shares?|views?|followers?)\s*$', multiLine: true, caseSensitive: false), '')
        // Remove trailing colons that are often part of masthead / label text
        .replaceAll(RegExp(r':+\s*$'), '')
        // ── OCR spacing fixes ──
        // Insert space between digit→letter ("5new" → "5 new")
        .replaceAllMapped(RegExp(r'(\d)([a-zA-Z])'), (m) => '${m[1]} ${m[2]}')
        // Insert space between letter→digit ("upto39" → "upto 39")
        .replaceAllMapped(RegExp(r'([a-zA-Z])(\d)'), (m) => '${m[1]} ${m[2]}')
        // Collapse multiple spaces
        .replaceAll(RegExp(r'\n+'), ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  /// Fallback: use first substantial-length lines if blocks unavailable
  String _extractHeadlineFallback(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 15)
        .where((l) => !RegExp(r'^[\d\s:@#]+$').hasMatch(l)) // ignore lines that are just numbers/timestamps
        .where((l) => !_isMasthead(l)) // skip masthead/logo lines
        .toList();
    if (lines.isEmpty) return rawText.trim().substring(0, rawText.trim().length.clamp(0, 200));
    // Pick the longest line from the first 8 lines (usually the headline)
    final topLines = lines.take(8).toList();
    topLines.sort((a, b) => b.length.compareTo(a.length));
    final headline = topLines.first;
    return headline.length > 200 ? '${headline.substring(0, 200)}…' : headline;
  }

  OcrConfidence _assessConfidence(String rawText, List<TextBlock> blocks) {
    final lower = rawText.toLowerCase();
    
    // Check for very low word count (blurry / QR code / irrelevant)
    final words = rawText.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    if (words.length < 4) return OcrConfidence.tooShort;
    if (words.length < 8) return OcrConfidence.lowConfidence;

    // Check for patterns suggesting it IS a news/social media screenshot
    final newsSignals = [
      RegExp(r'\b(news|report|says?|said|told|according|officials?|government|minister|president|pm|cm|police|court|attack|killed|arrested|died|injured|billion|million|crore|lakh|rupee|dollar)\b', caseSensitive: false),
    ];
    int newsSignalCount = 0;
    for (final pattern in newsSignals) {
      if (pattern.hasMatch(lower)) newsSignalCount++;
    }

    // Most screenshots with 10+ real words and some news signal → ok
    if (words.length >= 10 || newsSignalCount > 0) return OcrConfidence.good;
    return OcrConfidence.lowConfidence;
  }
}

enum OcrConfidence { good, lowConfidence, tooShort, noText, irrelevant }

class OcrResult {
  final String rawText;
  final String headline;
  final OcrConfidence confidence;

  const OcrResult({
    required this.rawText,
    required this.headline,
    required this.confidence,
  });

  bool get isUsable => confidence == OcrConfidence.good || confidence == OcrConfidence.lowConfidence;
  bool get isEmpty => confidence == OcrConfidence.noText || confidence == OcrConfidence.tooShort;
  bool get isIrrelevant => confidence == OcrConfidence.irrelevant;

  String get userMessage {
    switch (confidence) {
      case OcrConfidence.noText:
        return 'No text could be detected in this image. Please upload a clear news screenshot.';
      case OcrConfidence.tooShort:
        return 'The image contains too little text to verify. Please use a screenshot with a visible headline.';
      case OcrConfidence.irrelevant:
        return 'This image doesn\'t appear to contain news content. Please upload a news screenshot for verification.';
      case OcrConfidence.lowConfidence:
      case OcrConfidence.good:
        return '';
    }
  }
}

class _BlockScore {
  final String text;
  final double score;
  const _BlockScore({required this.text, required this.score});
}

/// A single text block with its bounding box for the scanner overlay.
class OcrTextBlock {
  final String text;
  final Rect rect;
  final List<String> lines;

  const OcrTextBlock({
    required this.text,
    required this.rect,
    required this.lines,
  });
}

/// All text blocks + image dimensions for the scanner overlay.
class OcrScanResult {
  final List<OcrTextBlock> blocks;
  final double imageWidth;
  final double imageHeight;
  final String fullText;

  const OcrScanResult({
    required this.blocks,
    required this.imageWidth,
    required this.imageHeight,
    required this.fullText,
  });
}
