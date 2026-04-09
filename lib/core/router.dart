import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/main.dart' show pendingShareImagePath;
import 'package:sachcheck/screens/auth/login_screen.dart';
import 'package:sachcheck/screens/auth/signup_screen.dart';
import 'package:sachcheck/screens/chat/chatroom_screen.dart';
import 'package:sachcheck/screens/editor/headline_editor_screen.dart';
import 'package:sachcheck/screens/history/history_detail_screen.dart';
import 'package:sachcheck/screens/history/history_screen.dart';
import 'package:sachcheck/screens/home/home_screen.dart';
import 'package:sachcheck/screens/onboarding/onboarding_screen.dart';
import 'package:sachcheck/screens/processing/processing_screen.dart';
import 'package:sachcheck/screens/profile/profile_screen.dart';
import 'package:sachcheck/screens/result/result_screen.dart';
import 'package:sachcheck/screens/settings/settings_screen.dart';
import 'package:sachcheck/screens/splash/splash_screen.dart';
import 'package:sachcheck/models/history_item.dart';
import 'package:sachcheck/models/verification_result.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Shell navigator key — bottom nav lives here
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup';
    final isSplash = state.matchedLocation == '/';
    final isOnboarding = state.matchedLocation == '/onboarding';

    // Allow splash and onboarding always
    if (isSplash || isOnboarding) return null;

    // Not logged in → go to login (unless already on auth route)
    if (user == null && !isAuthRoute) return '/login';

    // Logged in but on auth route → go home
    // If a shared image is pending, redirect to /processing instead
    if (user != null && isAuthRoute) {
      if (pendingShareImagePath != null) {
        return '/home'; // go to home first; share is handled post-build
      }
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),

    // ── Shell Route with 4-tab bottom nav ─────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) =>
          _ScaffoldWithNav(state: state, child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/chatroom', builder: (_, __) => const ChatroomScreen()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // ── Full-screen routes (no bottom nav) ────────────────────────────────
    GoRoute(
      path: '/processing',
      builder: (_, state) {
        final imagePath = state.extra as String;
        return ProcessingScreen(imagePath: imagePath);
      },
    ),
    GoRoute(
      path: '/editor',
      builder: (_, state) {
        final data = state.extra as Map<String, dynamic>;
        return HeadlineEditorScreen(
          imagePath: data['imagePath'] as String,
          extractedHeadline: data['headline'] as String,
          rawText: data['rawText'] as String,
        );
      },
    ),
    GoRoute(
      path: '/result',
      builder: (_, state) {
        final result = state.extra as VerificationResult;
        return ResultScreen(result: result);
      },
    ),
    GoRoute(
      path: '/history-detail',
      builder: (_, state) {
        final item = state.extra as HistoryItem;
        return HistoryDetailScreen(item: item);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);

// ── Bottom Navigation Shell ───────────────────────────────────────────────
class _ScaffoldWithNav extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const _ScaffoldWithNav({required this.state, required this.child});

  int _index(String location) {
    if (location.startsWith('/chatroom')) return 1;
    if (location.startsWith('/history')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfColor = isDark ? AppColors.surface : AppColors.lightSurface;
    final txtSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final idx = _index(state.matchedLocation);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfColor,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.divider : AppColors.lightDivider,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          type: BottomNavigationBarType.fixed,
          backgroundColor: surfColor,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: txtSec,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          onTap: (i) {
            switch (i) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/chatroom');
                break;
              case 2:
                context.go('/history');
                break;
              case 3:
                context.go('/profile');
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
