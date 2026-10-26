import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendx/core/constants/app_constants.dart';
import 'package:attendx/shared/widgets/glass_card.dart';
import 'package:attendx/shared/widgets/gradient_button.dart';

void main() {
  group('Haversine Proximity Verification Tests', () {
    test('Zero distance for identical coordinates', () {
      final distance = HaversineUtil.distanceInMetres(
        12.9716, 77.5946,
        12.9716, 77.5946,
      );
      expect(distance, closeTo(0.0, 0.001));
    });

    test('Distance within 20m threshold', () {
      // Offset by approx 0.0001 degrees lat (~11 metres)
      final distance = HaversineUtil.distanceInMetres(
        12.971600, 77.594600,
        12.971700, 77.594600,
      );
      expect(distance, lessThan(20.0));
      expect(distance, greaterThan(5.0));
    });

    test('Distance outside 20m threshold triggers violation', () {
      // Offset by 0.001 degrees lat (~111 metres)
      final distance = HaversineUtil.distanceInMetres(
        12.971600, 77.594600,
        12.972600, 77.594600,
      );
      expect(distance, greaterThan(AppConstants.maxDistanceMeters));
    });
  });

  group('UI Component Tests', () {
    testWidgets('GlassCard renders child content correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Classroom Proximity Verified'),
            ),
          ),
        ),
      );

      expect(find.text('Classroom Proximity Verified'), findsOneWidget);
    });

    testWidgets('GradientButton responds to tap and shows loading state', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              onPressed: () => tapped = true,
              child: const Text('GENERATE OTP'),
            ),
          ),
        ),
      );

      expect(find.text('GENERATE OTP'), findsOneWidget);
      await tester.tap(find.text('GENERATE OTP'));
      expect(tapped, isTrue);

      // Test loading state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GradientButton(
              isLoading: true,
              child: Text('GENERATE OTP'),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
