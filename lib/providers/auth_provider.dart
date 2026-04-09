import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sachcheck/services/auth_service.dart';

// ── Auth service singleton ─────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Auth state stream ──────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── User profile stream ────────────────────────────────────────────────────
final userProfileStreamProvider =
    StreamProvider<Map<String, dynamic>?>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return Stream.value(null);
  return ref.watch(authServiceProvider).userProfileStream();
});
