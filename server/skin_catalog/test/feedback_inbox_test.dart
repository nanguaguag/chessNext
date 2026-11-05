import 'dart:convert';
import 'dart:io';

import 'package:skin_catalog_server/skin_catalog_server.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late Directory inboxDir;
  late Directory copyrightInboxDir;
  late SkinCatalogHttpServer server;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('chessnext-feedback-test-');
    final manifest = Directory('${root.path}/catalog')..createSync();
    await File(
      '${manifest.path}/catalog.json',
    ).writeAsString('{"schema":1,"skins":[]}');
    inboxDir = Directory('${root.path}/inbox');
    await inboxDir.create();
    copyrightInboxDir = Directory('${root.path}/copyright-inbox');
    await copyrightInboxDir.create();
    server = await SkinCatalogHttpServer.bind(
      store: await SkinCatalogStore.load(manifest),
      feedbackInbox: await FeedbackInbox.open(inboxDir),
      copyrightComplaintInbox: await CopyrightComplaintInbox.open(
        copyrightInboxDir,
      ),
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

  test('accepts complaint fields into the separate private inbox', () async {
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('${server.baseUrl}/v1/copyright/complaints'),
    );
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'schema': 1,
        'complainant': 'Sample person',
        'email': 'person@example.test',
        'work': 'Sample work',
        'ownership': 'Created by complainant',
        'content': 'https://example.test/work',
      }),
    );
    final response = await request.close();
    expect(response.statusCode, HttpStatus.created);
    await response.drain<void>();
    final files = await copyrightInboxDir
        .list()
        .where((entity) => entity is File)
        .toList();
    expect(files, hasLength(1));
    final saved =
        jsonDecode(await (files.single as File).readAsString())
            as Map<String, dynamic>;
    expect(saved['complainant'], 'Sample person');
    expect(saved['email'], 'person@example.test');
    expect(await inboxDir.list().length, 0);
    final read = await client.getUrl(
      Uri.parse('${server.baseUrl}/v1/copyright/complaints'),
    );
    final readResponse = await read.close();
    expect(readResponse.statusCode, HttpStatus.notFound);
    await readResponse.drain<void>();
    client.close(force: true);
  });

  test('rejects complaint payloads with unknown or invalid fields', () async {
    final client = HttpClient();
    for (final payload in [
      {
        'schema': 1,
        'complainant': 'x',
        'email': 'x@y',
        'work': 'x',
        'ownership': 'x',
        'content': 'x',
        'device': 'private',
      },
      {
        'schema': 1,
        'complainant': 'x',
        'email': 'bad',
        'work': 'x',
        'ownership': 'x',
        'content': 'x',
      },
    ]) {
      final request = await client.postUrl(
        Uri.parse('${server.baseUrl}/v1/copyright/complaints'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();
      expect(response.statusCode, HttpStatus.badRequest);
      await response.drain<void>();
    }
    expect(await copyrightInboxDir.list().length, 0);
    client.close(force: true);
  });
}
