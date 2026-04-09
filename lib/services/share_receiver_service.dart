import 'package:flutter/services.dart';

/// Receives images shared from other apps via Android's share sheet.
///
/// Uses a MethodChannel to communicate with the native Android activity
/// which extracts the shared image URI and converts it to a local file path.
class ShareReceiverService {
  static const _channel = MethodChannel('com.sachcheck.sachcheck/share');

  /// Returns the file path of a shared image, or `null` if no image was shared.
  static Future<String?> getSharedImage() async {
    try {
      final String? path = await _channel.invokeMethod('getSharedImage');
      return (path != null && path.isNotEmpty) ? path : null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Clears the stored shared image so it isn't re-processed.
  static Future<void> clearSharedImage() async {
    try {
      await _channel.invokeMethod('clearSharedImage');
    } catch (_) {
      // Non-critical
    }
  }
}
