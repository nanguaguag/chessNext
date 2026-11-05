import 'package:chess_next/app.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('offline about shows package version and local licenses', (
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

    expect(find.byType(AboutDialog), findsOneWidget);
    expect(find.text('chessNext'), findsWidgets);
    expect(find.text('0.1.0+1'), findsOneWidget);
    expect(find.text('本版本未配置更新或反馈服务，不会在后台联网检查更新或发送设备信息。'), findsOneWidget);
    expect(repository.value, isNull);

    final licensesLabel = MaterialLocalizations.of(
      tester.element(find.byType(AboutDialog)),
    ).viewLicensesButtonLabel;
    final viewLicenses = find.text(licensesLabel);
    expect(viewLicenses, findsOneWidget);
    await tester.tap(viewLicenses);
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    expect(repository.value, isNull);
    expect(tester.takeException(), isNull);
  });
}
