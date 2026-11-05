import 'dart:async';
import 'dart:io';

import 'package:skin_catalog_server/skin_catalog_server.dart';

Future<void> main(List<String> args) async {
  final root = Directory(Platform.environment['SKIN_CATALOG_ROOT'] ?? './data');
  final addressText =
      Platform.environment['SKIN_CATALOG_ADDRESS'] ?? '127.0.0.1';
  final port = int.tryParse(
    Platform.environment['SKIN_CATALOG_PORT'] ?? '8087',
  );
  final address = InternetAddress.tryParse(addressText);
  if (args.isNotEmpty ||
      address == null ||
      port == null ||
      port < 1 ||
      port > 65535) {
    stderr.writeln(
      'Usage: SKIN_CATALOG_ROOT=./data SKIN_CATALOG_ADDRESS=127.0.0.1 '
      'SKIN_CATALOG_PORT=8087 dart run bin/skin_catalog_server.dart',
    );
    exitCode = 64;
    return;
  }
  final store = await SkinCatalogStore.load(root);
  final boardRoot = Platform.environment['SKIN_BOARD_CATALOG_ROOT'];
  final boardStore = boardRoot == null || boardRoot.trim().isEmpty
      ? null
      : await SkinCatalogStore.load(
          Directory(boardRoot),
          manifestName: 'board-catalog.json',
          packageDirectoryName: 'board-packages',
        );
  final bookRoot = Platform.environment['CHESSNEXT_BOOK_ROOT'];
  final bookDatabase = bookRoot == null || bookRoot.trim().isEmpty
      ? null
      : await BookDatabase.load(Directory(bookRoot));
  final releaseRoot = Platform.environment['CHESSNEXT_RELEASE_ROOT'];
  final releaseManifest = releaseRoot == null || releaseRoot.trim().isEmpty
      ? null
      : await ReleaseManifest.load(Directory(releaseRoot));
  final feedbackRoot = Platform.environment['CHESSNEXT_FEEDBACK_ROOT'];
  final feedbackInbox = feedbackRoot == null || feedbackRoot.trim().isEmpty
      ? null
      : await FeedbackInbox.open(Directory(feedbackRoot));
  final copyrightRoot = Platform.environment['CHESSNEXT_COPYRIGHT_ROOT'];
  final copyrightComplaintInbox =
      copyrightRoot == null || copyrightRoot.trim().isEmpty
      ? null
      : await CopyrightComplaintInbox.open(Directory(copyrightRoot));
  final server = await SkinCatalogHttpServer.bind(
    store: store,
    boardStore: boardStore,
    bookDatabase: bookDatabase,
    releaseManifest: releaseManifest,
    feedbackInbox: feedbackInbox,
    copyrightComplaintInbox: copyrightComplaintInbox,
    address: address,
    port: port,
  );
  stdout.writeln('Skin catalog listening at ${server.baseUrl}');
  stdout.writeln('Loaded ${store.skins.length} public entries.');
  if (boardStore != null) {
    stdout.writeln('Loaded ${boardStore.skins.length} public board skins.');
  }
  if (bookDatabase != null) {
    stdout.writeln(
      'Loaded ${bookDatabase.entryCount} operator-supplied book positions.',
    );
  }
  if (releaseManifest != null) {
    stdout.writeln(
      'Loaded ${releaseManifest.releases.length} operator-supplied releases.',
    );
  }
  if (feedbackInbox != null) stdout.writeln('Feedback inbox enabled.');
  if (copyrightComplaintInbox != null)
    stdout.writeln('Copyright complaint inbox enabled.');
  final stopped = Completer<void>();
  ProcessSignal.sigint.watch().listen((_) => stopped.complete());
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) => stopped.complete());
  }
  await stopped.future;
  await server.close();
}
