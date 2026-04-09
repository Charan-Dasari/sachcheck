// Basic smoke test for SachDrishti app.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sachcheck/models/history_item.dart';

void main() {
  testWidgets('App Hive init works', (WidgetTester tester) async {
    Hive.init('.');
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HistoryItemAdapter());
    }
    await Hive.openBox<HistoryItem>('history');

    expect(Hive.isBoxOpen('history'), isTrue);

    await Hive.close();
  });
}
