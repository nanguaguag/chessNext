import 'package:chess_next/app.dart';
import 'package:chess_next/features/settings/about_support_dialog.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:chess_next/ports/release_service.dart';
import 'package:chess_next/ports/feedback_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offline about keeps update check disabled and shows licenses', (
    tester,
  ) async {
    final repository = MemoryPreferencesRepository();
    await tester.pumpWidget(ChessNextApp(preferencesRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('应用设置'));
    await tester.pumpAndSettle();
    final aboutButton = find.byKey(const ValueKey('about-support'));
    await tester.ensureVisible(aboutButton);
    await tester.tap(aboutButton);
    await tester.pumpAndSettle();

    expect(find.text('当前版本 0.1.0+1'), findsOneWidget);
    expect(find.textContaining('未配置更新/反馈服务'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('check-release-updates')),
          )
          .onPressed,
      isNull,
    );
    expect(repository.value, isNull);

    await tester.tap(find.text('开源许可'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    expect(repository.value, isNull);
  });

  testWidgets(
    'configured release metadata is checked only after explicit tap',
    (tester) async {
      final service = _FakeReleaseService();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AboutSupportDialog(
                  releaseEndpoint: 'https://updates.example.test',
                  releaseService: service,
                  feedbackService: _FakeFeedbackService(),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(service.calls, 0);

      await tester.tap(find.byKey(const ValueKey('check-release-updates')));
      await tester.pumpAndSettle();
      expect(service.calls, 1);
      expect(service.endpoint, Uri.parse('https://updates.example.test'));
      expect(find.text('发现新版本'), findsOneWidget);
      expect(find.text('服务端版本 0.2.0+2 · 2026-11-05'), findsOneWidget);
      expect(find.text('修复和改进'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _FakeFeedbackService implements FeedbackService {
  @override
  Future<void> submit({
    required Uri endpoint,
    required FeedbackSubmission feedback,
  }) async {}
}

final class _FakeReleaseService implements ReleaseService {
  int calls = 0;
  Uri? endpoint;

  @override
  Future<ReleaseMetadata> fetchLatest({required Uri endpoint}) async {
    calls++;
    this.endpoint = endpoint;
    return ReleaseMetadata(
      history: [
        ReleaseEntry(
          version: '0.2.0',
          build: 2,
          publishedAt: DateTime.utc(2026, 11, 5),
          notes: '修复和改进',
        ),
        ReleaseEntry(
          version: '0.1.0',
          build: 1,
          publishedAt: DateTime.utc(2026, 11, 1),
          notes: '初始版本',
        ),
      ],
    );
  }
}
