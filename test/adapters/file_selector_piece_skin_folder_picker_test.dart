import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:chess_next/adapters/platform/file_selector_piece_skin_folder_picker.dart';
import 'package:chess_next/application/piece_skin_package_codec.dart';
import 'package:chess_next/ports/piece_skin_library.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:chess_next/ports/piece_skin_package_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as raster;

void main() {
  test('imports an extracted project skin package folder', () async {
    final root = await Directory.systemTemp.createTemp('skin-folder-');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/images').create();
    final archive = ZipDecoder().decodeBytes(
      PieceSkinPackageCodec.encode(
        PieceSkinDefinition(
          id: 'custom-source123',
          name: '松石',
          baseSkin: PieceSkin.roundSeal,
        ),
        {
          PieceImageSlot.redRook: Uint8List.fromList(
            raster.encodePng(raster.Image(width: 2, height: 2)),
          ),
        },
      ),
    );
    for (final entry in archive.files.where((entry) => entry.isFile)) {
      final path = '${root.path}/${entry.name}';
      await File(path).parent.create(recursive: true);
      await File(path).writeAsBytes(entry.readBytes()!);
    }
    final picker = FileSelectorPieceSkinFolderPicker(
      chooser: () async => root.path,
    );
    final bytes = await picker.pickFolderPackage();
    final decoded = PieceSkinPackageCodec.decode(bytes!);
    expect(decoded.profile.name, '松石');
    expect(decoded.images.keys, [PieceImageSlot.redRook]);
  });

  test('rejects unexpected files before importing', () async {
    final root = await Directory.systemTemp.createTemp('skin-folder-');
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/notes.txt').writeAsString('extra');
    final picker = FileSelectorPieceSkinFolderPicker(
      chooser: () async => root.path,
    );
    await expectLater(
      picker.pickFolderPackage(),
      throwsA(
        isA<PieceSkinPackageReadException>().having(
          (error) => error.failure,
          'failure',
          PieceSkinPackageReadFailure.read,
        ),
      ),
    );
  });
}
