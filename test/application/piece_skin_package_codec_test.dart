import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:chess_next/application/piece_skin_package_codec.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:chess_next/ports/piece_skin_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as raster;

void main() {
  test('exports profile metadata and validated slot images to ZIP', () {
    final png = Uint8List.fromList(
      raster.encodePng(raster.Image(width: 2, height: 2)),
    );
    final profile = PieceSkinDefinition(
      id: 'custom-abcdefgh',
      name: '导出测试',
      baseSkin: PieceSkin.squareInk,
      scalePercent: 111,
      offsetXPercent: -4,
    );
    final zip = PieceSkinPackageCodec.encode(profile, {
      PieceImageSlot.redHorse: png,
    });
    final decodedPackage = PieceSkinPackageCodec.decode(zip);
    expect(decodedPackage.profile, profile);
    expect(decodedPackage.images[PieceImageSlot.redHorse], png);
    final archive = ZipDecoder().decodeBytes(zip);
    expect(archive.files.map((file) => file.name).toSet(), {
      'skin.json',
      'images/redHorse.png',
    });
    final manifest =
        jsonDecode(utf8.decode(archive.findFile('skin.json')!.readBytes()!))
            as Map<String, dynamic>;
    expect(manifest['schema'], 1);
    expect(manifest['profile'], profile.toJson());
    expect((manifest['images'] as List).single['slot'], 'redHorse');
    expect(archive.findFile('images/redHorse.png')!.readBytes(), png);
  });

  test('rejects unsupported or invalid images', () {
    final profile = PieceSkinDefinition(
      id: 'custom-abcdefgh',
      name: '测试',
      baseSkin: PieceSkin.roundSeal,
    );
    expect(
      () => PieceSkinPackageCodec.encode(profile, {
        PieceImageSlot.redRook: Uint8List.fromList([1, 2, 3]),
      }),
      throwsFormatException,
    );
  });

  test('rejects path traversal entries in untrusted ZIP packages', () {
    final profile = PieceSkinDefinition(
      id: 'custom-exported1',
      name: '测试皮肤',
      baseSkin: PieceSkin.roundSeal,
    );
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'skin.json',
          jsonEncode({
            'schema': 1,
            'profile': profile.toJson(),
            'images': [
              {
                'slot': PieceImageSlot.redRook.name,
                'path': 'images/../../outside.png',
                'sha256': List.filled(64, '0').join(),
              },
            ],
          }),
        ),
      )
      ..addFile(ArchiveFile.string('images/../../outside.png', 'bad'));
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    expect(() => PieceSkinPackageCodec.decode(bytes), throwsFormatException);
  });
}
