import 'package:flutter_test/flutter_test.dart';

/// Wait for an observable async barrier rather than a fixed number of frames.
Future<void> pumpUntil(WidgetTester tester, bool Function() predicate) async {
  for (var frame = 0; frame < 100 && !predicate(); frame++) {
    // Stream cleanup may complete in the real zone where the fake gateway was
    // created; pumping only Flutter's fake clock cannot drain that future.
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(predicate(), isTrue, reason: 'Expected async state within 100 frames');
  await tester.pump();
}
