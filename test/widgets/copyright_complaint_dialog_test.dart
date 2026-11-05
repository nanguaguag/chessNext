import 'package:chess_next/features/settings/copyright_complaint_dialog.dart';
import 'package:chess_next/ports/copyright_complaint_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires truth declaration and previews before sending', (
    tester,
  ) async {
    final service = _FakeComplaintService();
    await tester.pumpWidget(
      MaterialApp(
        home: CopyrightComplaintDialog(
          endpoint: 'https://support.example.test',
          service: service,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('complaint-field-0')),
      'Sample complainant',
    );
    await tester.enterText(
      find.byKey(const ValueKey('complaint-field-1')),
      'person@example.test',
    );
    await tester.enterText(
      find.byKey(const ValueKey('complaint-field-2')),
      'Sample work',
    );
    await tester.enterText(
      find.byKey(const ValueKey('complaint-field-3')),
      'I created it',
    );
    await tester.enterText(
      find.byKey(const ValueKey('complaint-field-4')),
      'https://example.test/content',
    );
    await tester.tap(find.byKey(const ValueKey('preview-complaint')));
    await tester.pumpAndSettle();
    expect(find.text('请先确认声明真实、准确。'), findsOneWidget);
    expect(service.calls, 0);

    final truth = find.byKey(const ValueKey('complaint-truth'));
    await tester.ensureVisible(truth);
    await tester.tap(truth);
    await tester.tap(find.byKey(const ValueKey('preview-complaint')));
    await tester.pumpAndSettle();
    expect(service.calls, 0);
    expect(find.textContaining('https://support.example.test'), findsOneWidget);
    expect(find.text('Sample work'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('confirm-send-complaint')));
    await tester.pumpAndSettle();
    expect(service.calls, 1);
    expect(service.complaint?.email, 'person@example.test');
    expect(tester.takeException(), isNull);
  });
}

final class _FakeComplaintService implements CopyrightComplaintService {
  int calls = 0;
  CopyrightComplaintSubmission? complaint;
  @override
  Future<void> submitCopyrightComplaint({
    required Uri endpoint,
    required CopyrightComplaintSubmission complaint,
  }) async {
    calls++;
    this.complaint = complaint;
  }
}
