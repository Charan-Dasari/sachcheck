import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sachcheck/core/router.dart';
import 'package:sachcheck/core/theme.dart';
import 'package:sachcheck/models/history_item.dart';
import 'package:sachcheck/services/share_receiver_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If native already initialized the default app but with different options
    // (due to mismatches with google-services.json), we fallback.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }

  // Initialize Hive local storage
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryItemAdapter());
  await Hive.openBox<HistoryItem>('history');

  // Check for a shared image from the Android share sheet
  final sharedImagePath = await ShareReceiverService.getSharedImage();
  if (sharedImagePath != null) {
    pendingShareImagePath = sharedImagePath;
    await ShareReceiverService.clearSharedImage();
  }

  runApp(const ProviderScope(child: SachDrishtiApp()));
}

/// Global mutable that the router checks after auth to auto-navigate.
String? pendingShareImagePath;

class SachDrishtiApp extends StatelessWidget {
  const SachDrishtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'SachDrishti',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
