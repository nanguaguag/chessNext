import 'package:chess_next/features/settings/feedback_dialog.dart';
import 'package:chess_next/ports/feedback_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows exact payload and sends only after explicit confirmation',
    (tester) async {
      final service = _FakeFeedbackService();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => FeedbackDialog(
                  endpoint: 'https://feedback.example.test',
                  service: service,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('feedback-message')),
        '建议增加夜间主题',
      );
      await tester.enterText(
        find.byKey(const ValueKey('feedback-contact')),
        'mail@example.test',
      );
      await tester.tap(find.byKey(const ValueKey('preview-feedback')));
      await tester.pumpAndSettle();
      expect(service.calls, 0);
      expect(
        find.textContaining('https://feedback.example.test'),
        findsNWidgets(2),
      );
      expect(find.text('建议增加夜间主题'), findsNWidgets(2));
      expect(find.textContaining('mail@example.test'), findsNWidgets(2));
      expect(find.textContaining('不附加设备、浏览器、系统、棋谱或诊断信息'), findsOneWidget);
      expect(find.textContaining('来源IP等网络信息'), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('confirm-send-feedback')));
      await tester.pumpAndSettle();
      expect(service.calls, 1);
      expect(service.endpoint, Uri.parse('https://feedback.example.test'));
      expect(service.feedback?.message, '建议增加夜间主题');
      expect(service.feedback?.contact, 'mail@example.test');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('requires a description and leaves the service untouched', (
    tester,
  ) async {
    final service = _FakeFeedbackService();
    await tester.pumpWidget(
      MaterialApp(
        home: FeedbackDialog(
          endpoint: 'https://feedback.example.test',
          service: service,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('preview-feedback')));
    await tester.pumpAndSettle();
    expect(find.text('请填写描述'), findsOneWidget);
    expect(service.calls, 0);
  });
}

final class _FakeFeedbackService implements FeedbackService {
  int calls = 0;
  Uri? endpoint;
  FeedbackSubmission? feedback;

  @override
  Future<void> submit({
    required Uri endpoint,
    required FeedbackSubmission feedback,
  }) async {
    calls++;
    this.endpoint = endpoint;
    this.feedback = feedback;
  }
}
