import 'dart:convert';
import 'dart:io';

import 'package:chess_next/adapters/network/http_piece_skin_catalog.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/piece_image_library_controller.dart';
import 'package:chess_next/application/piece_skin_library_controller.dart';
import 'package:chess_next/application/piece_skin_package_codec.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/piece_images.dart';
import 'package:chess_next/ports/piece_skin_catalog.dart';
import 'package:chess_next/ports/piece_skin_library.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skin_catalog_server/skin_catalog_server.dart';

void main() {
  test(
    'self-hosted service package reaches the local library with license data',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'skin-catalog-roundtrip-',
      );
      final packages = Directory('${root.path}/packages')..createSync();
      final archive = PieceSkinPackageCodec.encode(
        PieceSkinDefinition(
          id: 'custom-abcdefgh',
          name: 'Authorized sample',
          baseSkin: PieceSkin.roundSeal,
        ),
        const {},
      );
      await File(
        '${packages.path}/authorized-sample.zip',
      ).writeAsBytes(archive);
      await File('${root.path}/catalog.json').writeAsString(
        jsonEncode({
          'schema': 1,
          'skins': [
            {
              'id': 'authorized-sample',
              'name': 'Authorized sample',
              'author': 'ChessNext test fixture',
              'description': 'Self-created integration fixture.',
              'likes': 1,
              'publishedAt': '2026-11-04T00:00:00Z',
              'license': 'CC0-1.0',
              'attribution': 'ChessNext integration fixture',
              'packageSha256': sha256.convert(archive).toString(),
            },
          ],
        }),
      );

      final server = await SkinCatalogHttpServer.bind(
        store: await SkinCatalogStore.load(root),
        port: 0,
      );
      final catalog = HttpPieceSkinCatalog();
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
      final library = PieceSkinLibraryController(
        MemoryPieceSkinLibraryRepository(),
        images,
        preferences,
      );
      await library.initialize();
      addTearDown(() async {
        library.dispose();
        images.dispose();
        preferences.dispose();
        engine.dispose();
        catalog.close();
        await server.close();
        await root.delete(recursive: true);
      });

      final page = await catalog.search(
        endpoint: Uri.parse(server.baseUrl),
        query: 'Authorized',
        sort: PublicPieceSkinSort.recent,
      );
      final item = page.items.single;
      final bytes = await catalog.downloadPackage(
        endpoint: Uri.parse(server.baseUrl),
        id: item.id,
        expectedSha256: item.packageSha256,
      );
      final decoded = PieceSkinPackageCodec.decode(bytes);
      expect(decoded.profile.name, item.name);
      expect(
        await library.importPackage(
          decoded,
          license: item.license,
          attribution: item.attribution,
        ),
        isTrue,
      );
      expect(library.profiles.single.license, 'CC0-1.0');
      expect(
        library.profiles.single.attribution,
        'ChessNext integration fixture',
      );
      expect(preferences.value.selectedPieceSkinId, library.profiles.single.id);
    },
  );
}
