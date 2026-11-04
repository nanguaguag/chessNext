import 'package:chess_next/application/piece_skin_collection_package_codec.dart';
import 'package:chess_next/application/piece_skin_package_codec.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:chess_next/ports/piece_skin_library.dart';
import 'package:flutter_test/flutter_test.dart';

PieceSkinPackage _package(String id, String name) => PieceSkinPackage(
  profile: PieceSkinDefinition(
    id: id,
    name: name,
    baseSkin: PieceSkin.roundSeal,
    license: 'CC-BY-4.0',
    attribution: '原创作者',
  ),
  images: const {},
);

void main() {
  test('round trips a bounded collection and preserves attribution', () {
    final bytes = PieceSkinCollectionPackageCodec.encode([
      _package('custom-exported01', '皮肤甲'),
      _package('custom-exported02', '皮肤乙'),
    ]);
    final decoded = PieceSkinCollectionPackageCodec.decode(bytes);
    expect(decoded.packages.map((item) => item.profile.name), ['皮肤甲', '皮肤乙']);
    expect(decoded.packages.first.profile.license, 'CC-BY-4.0');
    expect(decoded.packages.first.profile.attribution, '原创作者');
  });

  test('rejects invalid counts, duplicate names, and truncated archives', () {
    expect(
      () => PieceSkinCollectionPackageCodec.encode([
        _package('custom-exported01', '仅一套'),
      ]),
      throwsFormatException,
    );
    expect(
      () => PieceSkinCollectionPackageCodec.encode([
        _package('custom-exported01', '重复'),
        _package('custom-exported02', '重复'),
      ]),
      throwsFormatException,
    );
    expect(
      () => PieceSkinCollectionPackageCodec.encode([
        for (var i = 0; i < 17; i++)
          _package('custom-exported${i.toString().padLeft(2, '0')}', '皮肤$i'),
      ]),
      throwsFormatException,
    );
    final bytes = PieceSkinCollectionPackageCodec.encode([
      _package('custom-exported01', '皮肤甲'),
      _package('custom-exported02', '皮肤乙'),
    ]);
    expect(
      () => PieceSkinCollectionPackageCodec.decode(
        bytes.sublist(0, bytes.length - 1),
      ),
      throwsFormatException,
    );
  });
}
