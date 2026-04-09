import 'dart:io';
import 'package:http/http.dart' as http;

/// Simple connectivity check service.
class ConnectivityService {
  /// Returns true if the device has internet access.
  static Future<bool> hasInternet() async {
    try {
      final response = await http.head(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
