import 'dart:typed_data';

import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/piece_image_library_controller.dart';
import 'package:chess_next/application/piece_skin_library_controller.dart';
import 'package:chess_next/application/piece_skin_package_codec.dart';
import 'package:chess_next/application/piece_skin_collection_package_codec.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/features/settings/piece_skin_library_dialog.dart';
import 'package:chess_next/ports/piece_skin_catalog.dart';
import 'package:chess_next/ports/piece_skin_library.dart';
import 'package:chess_next/ports/piece_skin_package_picker.dart';
import 'package:chess_next/ports/piece_skin_package_exporter.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:chess_next/ports/record_file_exporter.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Catalog implements PieceSkinCatalog {
  bool unavailable = false;
  bool stale = false;
  Uri? requestedEndpoint;
  Uint8List packageBytes = PieceSkinPackageCodec.encode(
    PieceSkinDefinition(
      id: 'custom-abcdefgh',
      name: '原创红章',
      baseSkin: PieceSkin.roundSeal,
    ),
    const {},
  );
  @override
  Future<PieceSkinCatalogPage> search({
    required Uri endpoint,
    required String query,
    required PublicPieceSkinSort sort,
    int page = 1,
    int pageSize = 24,
  }) async {
    requestedEndpoint = endpoint;
    if (unavailable) throw const PieceSkinCatalogUnavailable();
    return PieceSkinCatalogPage(
      items: [
        PublicPieceSkin(
          id: 'original-red',
          name: '原创红章',
          author: '作者甲',
          description: '原创作品',
          likes: 7,
          publishedAt: DateTime.utc(2026, 10, 20),
          license: 'CC-BY-4.0',
          attribution: '作者甲 / 棋友社区',
          packageSha256: List.filled(64, 'a').join(),
        ),
      ],
      page: page,
      pageSize: pageSize,
      total: 1,
      isStale: stale,
      cachedAt: stale ? DateTime.utc(2026, 11, 4, 8) : null,
    );
  }

  @override
  Future<Uint8List> downloadPackage({
    required Uri endpoint,
    required String id,
    required String expectedSha256,
  }) async => packageBytes;
}

class _StaticPackagePicker implements PieceSkinPackagePicker {
  _StaticPackagePicker(this.bytes);
  final Uint8List bytes;

  @override
  Future<Uint8List?> pickZip() async => bytes;
}

class _MemoryPackageExporter implements PieceSkinPackageExporter {
  Uint8List? bytes;

  @override
  Future<RecordFileExportResult> saveZip({
    required String suggestedName,
    required Uint8List bytes,
    required FileExportCancellation cancellation,
  }) async {
    this.bytes = Uint8List.fromList(bytes);
    return RecordFileExportResult.saved;
  }
}

void main() {
  testWidgets('exports selected profiles as one validated collection ZIP', (
    tester,
  ) async {
    final engine = EngineSessionController(BoardSession(), null);
    final preferences = PreferencesController(
      engine,
      MemoryPreferencesRepository(),
    );
    await preferences.initialize();
    final images = PieceImageLibraryController(
      const CancelPieceImagePicker(),
      MemoryPieceImageRepository(),
    );
    await images.initialize();
    final skins = PieceSkinLibraryController(
      MemoryPieceSkinLibraryRepository(),
      images,
      preferences,
    );
    await skins.initialize();
    await skins.create(name: '导出皮肤甲');
    await skins.create(name: '导出皮肤乙');
    final exporter = _MemoryPackageExporter();
    addTearDown(() {
      skins.dispose();
      images.dispose();
      preferences.dispose();
      engine.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    PieceSkinLibraryDialog(library: skins, exporter: exporter),
              ),
              child: const Text('打开皮肤库'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开皮肤库'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '导出所选 0 套'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导出所选 2 套'));
    await tester.pumpAndSettle();
    final decoded = PieceSkinCollectionPackageCodec.decode(exporter.bytes!);
    expect(decoded.packages.map((item) => item.profile.name).toSet(), {
      '导出皮肤甲',
      '导出皮肤乙',
    });
  });

  testWidgets('validates a collection then imports only selected skins', (
    tester,
  ) async {
    final engine = EngineSessionController(BoardSession(), null);
    final preferences = PreferencesController(
      engine,
      MemoryPreferencesRepository(),
    );
    await preferences.initialize();
    final images = PieceImageLibraryController(
      const CancelPieceImagePicker(),
      MemoryPieceImageRepository(),
    );
    await images.initialize();
    final skins = PieceSkinLibraryController(
      MemoryPieceSkinLibraryRepository(),
      images,
      preferences,
    );
    await skins.initialize();
    final collection = PieceSkinCollectionPackageCodec.encode([
      for (var i = 1; i <= 2; i++)
        PieceSkinPackage(
          profile: PieceSkinDefinition(
            id: 'custom-exported0$i',
            name: '集合皮肤$i',
            baseSkin: PieceSkin.roundSeal,
            license: i == 1 ? 'CC-BY-4.0' : '',
            attribution: i == 1 ? '作者甲' : '',
          ),
          images: const {},
        ),
    ]);
    addTearDown(() {
      skins.dispose();
      images.dispose();
      preferences.dispose();
      engine.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PieceSkinLibraryDialog(
                  library: skins,
                  picker: _StaticPackagePicker(collection),
                ),
              ),
              child: const Text('打开皮肤库'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开皮肤库'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导入ZIP'));
    await tester.pumpAndSettle();
    expect(find.text('集合皮肤1'), findsOneWidget);
    expect(find.text('集合皮肤2'), findsOneWidget);
    expect(find.textContaining('许可：CC-BY-4.0'), findsOneWidget);
    expect(find.textContaining('署名：作者甲'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('接受许可并导入 1 套'));
    await tester.pumpAndSettle();
    expect(skins.profiles.map((profile) => profile.name), ['集合皮肤1']);
    expect(preferences.value.selectedPieceSkinId, skins.profiles.single.id);
  });

  testWidgets('saves self-hosted endpoint and shows license before import', (
    tester,
  ) async {
    final engine = EngineSessionController(BoardSession(), null);
    final preferences = PreferencesController(
      engine,
      MemoryPreferencesRepository(),
    );
    await preferences.initialize();
    final images = PieceImageLibraryController(
      const CancelPieceImagePicker(),
      MemoryPieceImageRepository(),
    );
    await images.initialize();
    final skins = PieceSkinLibraryController(
      MemoryPieceSkinLibraryRepository(),
      images,
      preferences,
    );
    await skins.initialize();
    final catalog = _Catalog();
    addTearDown(() {
      skins.dispose();
      images.dispose();
      preferences.dispose();
      engine.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    PieceSkinLibraryDialog(library: skins, catalog: catalog),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'https://skins.example.org',
    );
    await tester.tap(find.byTooltip('保存服务地址并连接'));
    await tester.pumpAndSettle();
    expect(preferences.value.skinCatalogBaseUrl, 'https://skins.example.org');
    expect(catalog.requestedEndpoint?.host, 'skins.example.org');
    expect(find.textContaining('许可：CC-BY-4.0'), findsOneWidget);
    expect(find.textContaining('署名：作者甲 / 棋友社区'), findsOneWidget);
    catalog.stale = true;
    await tester.tap(find.byTooltip('刷新在线目录'));
    await tester.pumpAndSettle();
    expect(find.textContaining('离线缓存 ·'), findsOneWidget);
    await tester.tap(find.text('原创红章'));
    await tester.pumpAndSettle();
    expect(find.textContaining('当前不会自动写入本机'), findsOneWidget);
    await tester.tap(find.text('下载并确认导入'));
    await tester.pumpAndSettle();
    expect(find.text('接受许可并导入'), findsOneWidget);
    expect(find.textContaining('许可证：CC-BY-4.0'), findsNWidgets(2));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(skins.profiles, isEmpty);
    await tester.tap(find.text('下载并确认导入'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('接受许可并导入'));
    await tester.pumpAndSettle();
    expect(skins.profiles.map((profile) => profile.name), contains('原创红章'));
    expect(skins.profiles.single.license, 'CC-BY-4.0');
    expect(skins.profiles.single.attribution, '作者甲 / 棋友社区');
  });

  testWidgets('reports offline catalog failure explicitly', (tester) async {
    final engine = EngineSessionController(BoardSession(), null);
    final preferences = PreferencesController(
      engine,
      MemoryPreferencesRepository(),
    );
    await preferences.initialize();
    await preferences.setSkinCatalogBaseUrl('https://skins.example.org');
    final images = PieceImageLibraryController(
      const CancelPieceImagePicker(),
      MemoryPieceImageRepository(),
    );
    await images.initialize();
    final skins = PieceSkinLibraryController(
      MemoryPieceSkinLibraryRepository(),
      images,
      preferences,
    );
    await skins.initialize();
    final catalog = _Catalog()..unavailable = true;
    addTearDown(() {
      skins.dispose();
      images.dispose();
      preferences.dispose();
      engine.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    PieceSkinLibraryDialog(library: skins, catalog: catalog),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('刷新在线目录'));
    await tester.pumpAndSettle();
    expect(find.text('无法连接自建皮肤目录，请检查网络和服务状态。'), findsOneWidget);
  });
}
