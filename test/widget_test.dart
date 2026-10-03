import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mindfull/app/app.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'overlay_enabled': true,
      'nudge_threshold_minutes': 20,
      'tracked_packages': <String>[],
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.mindfull/platform'),
      (MethodCall call) async {
        switch (call.method) {
          case 'checkUsagePermission':
            return true;
          case 'checkOverlayPermission':
            return true;
          case 'checkAccessibilityPermission':
            return false;
          case 'getTodayUsageStats':
            return {'totalTimeMs': 1200000, 'appStats': []};
          case 'getPast7DaysStats':
            return [];
          case 'getInstalledApps':
            return [];
          case 'isOverlayServiceRunning':
            return true;
          case 'startOverlayService':
          case 'stopOverlayService':
          case 'updateNotchState':
          case 'updateNotchSettings':
            return true;
          default:
            return null;
        }
      },
    );
  });

  testWidgets('Mindfull app renders main navigation shell', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MindfullApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    // Verify main destinations exist
    expect(find.text('Attention'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Mindfulness'), findsOneWidget);
    expect(find.text('Reflection'), findsOneWidget);
  });
}
