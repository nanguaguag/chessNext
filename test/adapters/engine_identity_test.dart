import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:chess_next/adapters/engine/verified_engine_bundle.dart';
import 'package:chess_next/ports/engine_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory folder;
  late Map<String, dynamic> data;
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('chessnext-identity-');
    const binary = [1, 2, 3, 4];
    const network = [5, 6, 7, 8];
    await File('${folder.path}/Pikafish-MacOS-universal').writeAsBytes(binary);
    await File('${folder.path}/pikafish.nnue').writeAsBytes(network);
    data = {
      'schema': 1,
      'release': 'Synthetic test fixture',
      'commit': 'a' * 40,
      'sourceBinarySha256': 'b' * 64,
      'binarySha256': sha256.convert(binary).toString(),
      'networkSha256': sha256.convert(network).toString(),
      'target': 'test',
    };
    await File('${folder.path}/identity.json').writeAsString(jsonEncode(data));
  });
  tearDown(() => folder.delete(recursive: true));
  test(
    'fixed-order identity survives JSON order and changes with every artifact',
    () {
      final a = EngineIdentity.fromJson(data);
      final reversed = Map<String, dynamic>.fromEntries(
        data.entries.toList().reversed,
      );
      expect(EngineIdentity.fromJson(reversed).cacheIdentity, a.cacheIdentity);
      for (final field in [
        'sourceBinarySha256',
        'binarySha256',
        'networkSha256',
      ]) {
        expect(
          EngineIdentity.fromJson({...data, field: 'c' * 64}).cacheIdentity,
          isNot(a.cacheIdentity),
        );
      }
      expect(
        EngineIdentity.fromJson({...data, 'commit': 'd' * 40}).cacheIdentity,
        isNot(a.cacheIdentity),
      );
      expect(
        EngineIdentity.fromJson({...data, 'target': 'other'}).cacheIdentity,
        isNot(a.cacheIdentity),
      );
    },
  );
  test('unknown schemas, malformed hashes/types and controls fail closed', () {
    for (final invalid in [
      {...data, 'schema': 2},
      {...data, 'binarySha256': 'x'},
      {...data, 'networkSha256': null},
      {...data, 'release': 'bad\nname'},
      {...data, 'commit': 10},
    ]) {
      expect(() => EngineIdentity.fromJson(invalid), throwsFormatException);
    }
  });
  test(
    'artifact verifier hashes exact files in worker isolate and records runtime ABI',
    () async {
      final verified = await verifyEngineBundle(folder.path);
      expect(verified.binarySha256, data['binarySha256']);
      expect(verified.networkSha256, data['networkSha256']);
      expect(verified.target, startsWith('test/'));
    },
  );
  test('changed executable cannot inherit the manifest identity', () async {
    await File('${folder.path}/Pikafish-MacOS-universal').writeAsBytes([9]);
    await expectLater(verifyEngineBundle(folder.path), throwsFormatException);
  });
  test('changed network cannot reuse a previous identity', () async {
    await File('${folder.path}/pikafish.nnue').writeAsBytes([9]);
    await expectLater(verifyEngineBundle(folder.path), throwsFormatException);
  });
  test(
    'missing or oversized manifest is rejected rather than guessed',
    () async {
      final manifest = File('${folder.path}/identity.json');
      await manifest.delete();
      await expectLater(
        verifyEngineBundle(folder.path),
        throwsA(isA<FileSystemException>()),
      );
      await manifest.writeAsString('x' * 16385);
      await expectLater(verifyEngineBundle(folder.path), throwsFormatException);
    },
  );
}
