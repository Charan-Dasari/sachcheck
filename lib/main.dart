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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
