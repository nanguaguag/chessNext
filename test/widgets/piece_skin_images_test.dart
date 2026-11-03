import 'dart:typed_data';

import 'package:chess_next/features/board/xiangqi_board.dart';
import 'package:chess_next/features/board/board_display_scope.dart';
import 'package:chess_next/app.dart';
import 'package:chess_next/application/piece_image_library_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as raster;
import 'package:xiangqi_core/xiangqi_core.dart';

class _BatchPiecePicker implements PieceImagePicker, PieceImageBatchPicker {
  _BatchPiecePicker(this.files);
  final List<NamedPieceImage> files;
  @override
  Future<SelectedPieceImage?> pickImage() async => null;
  @override
  Future<List<NamedPieceImage>?> pickImages() async => files;
}

void main() {
  testWidgets('piece skin nudges persist and auto-align resets both axes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryPreferencesRepository();
    await tester.pumpWidget(ChessNextApp(preferencesRepository: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('应用设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('棋盘显示'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('棋子右移1%'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('棋子上移1%'));
    await tester.pumpAndSettle();
    expect(store.value!.roundSealPieceOffsetX, 1);
    expect(store.value!.roundSealPieceOffsetY, -1);
    expect(
      tester
          .widget<Transform>(
            find.descendant(
              of: find.byKey(const ValueKey('square-a9')),
              matching: find.byKey(const ValueKey('piece-skin-position')),
            ),
          )
          .transformHitTests,
      isFalse,
    );
    await tester.tap(find.byTooltip('棋子自动对正'));
    await tester.pumpAndSettle();
    expect(store.value!.roundSealPieceOffsetX, 0);
    expect(store.value!.roundSealPieceOffsetY, 0);
    expect(find.byKey(const ValueKey('piece-skin-position')), findsNothing);
  });

  testWidgets('custom image replaces only the matching piece slot', (
    tester,
  ) async {
    final bytes = Uint8List.fromList(
      raster.encodePng(raster.Image(width: 2, height: 2)),
    );
    final position = Position.initial();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 450,
              child: BoardSurface(
                at: position.at,
                onTap: (_) {},
                pieceImages: {PieceImageSlot.blackRook: bytes},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('square-a9')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('square-a8')),
        matching: find.byType(Image),
      ),
      findsNothing,
    );
  });

  testWidgets('skin-specific scale combines with global size', (tester) async {
    final position = Position.initial();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 450,
              child: BoardDisplayScope(
                showCoordinates: true,
                pieceSizePercent: 150,
                pieceSkinSizePercent: 110,
                pieceSkinOffsetXPercent: 4,
                pieceSkinOffsetYPercent: -3,
                child: BoardSurface(at: position.at, onTap: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('square-a9')),
        matching: find.byKey(const ValueKey('piece-size')),
      ),
    );
    expect(transform.transform.storage[0], closeTo(1.65, 0.001));
    final translation = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('square-a9')),
        matching: find.byKey(const ValueKey('piece-skin-position')),
      ),
    );
    expect(translation.transform.getTranslation().x, greaterThan(0));
    expect(translation.transform.getTranslation().y, lessThan(0));
  });

  testWidgets('batch image import maps filenames and persists both slots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bytes = Uint8List.fromList(
      raster.encodePng(raster.Image(width: 2, height: 2)),
    );
    final repository = MemoryPieceImageRepository();
    await tester.pumpWidget(
      ChessNextApp(
        pieceImagePicker: _BatchPiecePicker([
          NamedPieceImage(
            name: 'redRook.png',
            image: SelectedPieceImage('png', bytes),
          ),
          NamedPieceImage(
            name: 'blackHorse.png',
            image: SelectedPieceImage('png', bytes),
          ),
        ]),
        pieceImageRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('应用设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('棋盘显示'));
    await tester.pumpAndSettle();
    final editImages = find.text('编辑棋子图片');
    await tester.ensureVisible(editImages);
    await tester.tap(editImages);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('batch-import-piece-images')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('apply-piece-image-batch')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('apply-piece-image-batch')));
    await tester.pumpAndSettle();
    final loaded = await repository.load();
    expect(loaded[PieceSkin.roundSeal]!.keys.toSet(), {
      PieceImageSlot.redRook,
      PieceImageSlot.blackHorse,
    });
    await tester.pumpAndSettle();
  });
}
