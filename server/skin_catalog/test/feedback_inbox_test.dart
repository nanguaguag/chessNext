import 'dart:convert';
import 'dart:io';

import 'package:skin_catalog_server/skin_catalog_server.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late Directory inboxDir;
  late SkinCatalogHttpServer server;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('chessnext-feedback-test-');
    final manifest = Directory('${root.path}/catalog')..createSync();
    await File(
      '${manifest.path}/catalog.json',
    ).writeAsString('{"schema":1,"skins":[]}');
    inboxDir = Directory('${root.path}/inbox');
    await inboxDir.create();
    server = await SkinCatalogHttpServer.bind(
      store: await SkinCatalogStore.load(manifest),
      feedbackInbox: await FeedbackInbox.open(inboxDir),
      port: 0,
    );
  });

  tearDown(() async {
    await server.close();
    await root.delete(recursive: true);
  });

  test(
    'accepts bounded user fields and never exposes stored messages',
    () async {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse('${server.baseUrl}/v1/feedback'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'schema': 1,
          'kind': 'problem',
          'message': '按钮无响应',
          'contact': 'a@example.test',
        }),
      );
      final response = await request.close();
      expect(response.statusCode, HttpStatus.created);
      expect(jsonDecode(await response.transform(utf8.decoder).join()), {
        'schema': 1,
        'accepted': true,
      });

      final files = await inboxDir
          .list()
          .where((entity) => entity is File)
          .toList();
      expect(files, hasLength(1));
      final saved =
          jsonDecode(await (files.single as File).readAsString())
              as Map<String, dynamic>;
      expect(saved['kind'], 'problem');
      expect(saved['message'], '按钮无响应');
      expect(saved['contact'], 'a@example.test');
      expect(saved.keys, containsAll(['receivedAt', 'schema']));

      final readRequest = await client.getUrl(
        Uri.parse('${server.baseUrl}/v1/feedback'),
      );
      final readResponse = await readRequest.close();
      expect(readResponse.statusCode, HttpStatus.notFound);
      client.close(force: true);
    },
  );

  test('rejects unsupported fields and oversized messages', () async {
    final client = HttpClient();
    for (final body in [
      {'schema': 1, 'kind': 'problem', 'message': 'x', 'device': 'secret'},
      {
        'schema': 1,
        'kind': 'problem',
        'message': List.filled(2001, 'x').join(),
      },
    ]) {
      final request = await client.postUrl(
        Uri.parse('${server.baseUrl}/v1/feedback'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close();
      expect(response.statusCode, HttpStatus.badRequest);
      await response.drain<void>();
    }
    expect(await inboxDir.list().length, 0);
    client.close(force: true);
  });
}
