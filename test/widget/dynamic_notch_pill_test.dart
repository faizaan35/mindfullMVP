import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindfull/features/overlay/domain/notch_state.dart';
import 'package:mindfull/features/overlay/presentation/dynamic_notch_pill.dart';

void main() {
  group('DynamicNotchPill Widget Tests', () {
    testWidgets('Renders collapsed pill correctly with duration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DynamicNotchPill(
                state: NotchState.collapsed,
                todayDuration: Duration(minutes: 18),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('18m'), findsOneWidget);
    });

    testWidgets('Renders app detected state with app name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DynamicNotchPill(
                state: NotchState.appDetected,
                appName: 'Instagram',
                todayDuration: Duration(minutes: 18),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('· 18m'), findsOneWidget);
    });

    testWidgets('Renders expanded state with action buttons', (tester) async {
      bool classifiedIntentional = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DynamicNotchPill(
                state: NotchState.expanded,
                appName: 'Instagram',
                todayDuration: const Duration(minutes: 18),
                sessionDuration: const Duration(minutes: 7),
                onClassifySession: (val) {
                  classifiedIntentional = val;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Today: 18m'), findsOneWidget);
      expect(find.text('Current session: 7m'), findsOneWidget);
      expect(find.text('Intentional'), findsOneWidget);
      expect(find.text('Unintentional'), findsOneWidget);

      await tester.tap(find.text('Intentional'));
      expect(classifiedIntentional, isTrue);
    });

    testWidgets('Renders contextual nudge state with task and return button', (tester) async {
      bool returnedToTask = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DynamicNotchPill(
                state: NotchState.contextualNudge,
                appName: 'Instagram',
                sessionDuration: const Duration(minutes: 24),
                activeTaskTitle: 'Finish DB assignment',
                onBackToTask: () {
                  returnedToTask = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Instagram · 24m'), findsOneWidget);
      expect(find.textContaining('Finish DB assignment'), findsOneWidget);
      expect(find.text('Return to Focus'), findsOneWidget);

      await tester.tap(find.text('Return to Focus'));
      expect(returnedToTask, isTrue);
    });
  });
}
