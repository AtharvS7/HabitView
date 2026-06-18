import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitview/core/constants/app_constants.dart';
import 'package:habitview/presentation/screens/splash/splash_screen.dart';
import 'package:habitview/presentation/widgets/metric_card.dart';

// The full app (`HabitViewApp`) now boots behind Firebase + Isar + a Riverpod
// `ProviderScope` created in `main()`, so it cannot be pumped directly without
// mocking those bootstrap dependencies. These smoke tests cover presentation
// widgets that are pure and dependency-free. End-to-end widget coverage lives
// in the Codespaces verification pass (see docs/TESTING.md).

void main() {
  testWidgets('SplashScreen shows the app name and a progress indicator',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('MetricCard renders its label, value and caption', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MetricCard(
          label: 'Consistency',
          value: '82%',
          caption: 'across all habits',
          icon: Icons.show_chart,
        ),
      ),
    ));

    expect(find.text('Consistency'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget);
    expect(find.text('across all habits'), findsOneWidget);
  });
}
