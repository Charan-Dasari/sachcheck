import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sachcheck/models/verification_result.dart';
import 'package:sachcheck/services/news_api_service.dart';
import 'package:sachcheck/services/ocr_service.dart';
import 'package:sachcheck/services/verification_engine.dart';

// Services
final newsApiServiceProvider = Provider<NewsApiService>((ref) => NewsApiService());
final ocrServiceProvider = Provider<OcrService>((ref) => OcrService());
final verificationEngineProvider = Provider<VerificationEngine>((ref) {
  return VerificationEngine(ref.read(newsApiServiceProvider));
});

// Verification state
sealed class VerificationState {
  const VerificationState();
}

class VerificationIdle extends VerificationState {
  const VerificationIdle();
}

class VerificationLoading extends VerificationState {
  final String statusMessage;
  const VerificationLoading(this.statusMessage);
}

class VerificationSuccess extends VerificationState {
  final VerificationResult result;
  const VerificationSuccess(this.result);
}

class VerificationError extends VerificationState {
  final String message;
  const VerificationError(this.message);
}

/// Returned when OCR finds no usable text (blurry/irrelevant image)
class VerificationInvalidImage extends VerificationState {
  final String message;
  const VerificationInvalidImage(this.message);
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  final OcrService _ocr;
  final VerificationEngine _engine;

  VerificationNotifier(this._ocr, this._engine) : super(const VerificationIdle());

  Future<VerificationResult?> verify(String imagePath) async {
    state = const VerificationLoading('Scanning image for text…');

    try {
      // Step 1: Extract text + headline using the improved OCR service
      final ocrResult = await _ocr.extractWithHeadline(imagePath);

      // Step 2: Validate that we got usable content
      if (!ocrResult.isUsable) {
        state = VerificationInvalidImage(ocrResult.userMessage);
        return null;
      }

      state = const VerificationLoading('Identifying main headline…');
      await Future.delayed(const Duration(milliseconds: 500));

      state = const VerificationLoading('Cross-checking with trusted sources…');

      final result = await _engine.verify(
        rawText: ocrResult.rawText,
        headline: ocrResult.headline.isNotEmpty ? ocrResult.headline : ocrResult.rawText,
        imagePath: imagePath,
      );

      state = VerificationSuccess(result);
      return result;
    } catch (e) {
      state = VerificationError(e.toString());
      return null;
    }
  }

  /// Verify using a user-edited headline (skips OCR extraction)
  Future<VerificationResult?> verifyWithHeadline({
    required String imagePath,
    required String headline,
    required String rawText,
  }) async {
    state = const VerificationLoading('Cross-checking with trusted sources…');
    try {
      final result = await _engine.verify(
        rawText: rawText,
        headline: headline,
        imagePath: imagePath,
      );
      state = VerificationSuccess(result);
      return result;
    } catch (e) {
      state = VerificationError(e.toString());
      return null;
    }
  }

  void reset() => state = const VerificationIdle();
}

final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  return VerificationNotifier(
    ref.read(ocrServiceProvider),
    ref.read(verificationEngineProvider),
  );
});
