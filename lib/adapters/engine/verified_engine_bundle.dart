import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import '../../ports/engine_identity.dart';

/// Hashing runs off the Flutter UI isolate, once per engine opening, not per go.
Future<EngineIdentity> verifyEngineBundle(String directory) =>
    Isolate.run(() => _verify(directory));

Future<EngineIdentity> _verify(String directory) async {
  final manifest = File('$directory/identity.json');
  if (await manifest.length() > 16384) {
    throw const FormatException('Engine manifest too large');
  }
  final data = jsonDecode(await manifest.readAsString());
  if (data is! Map<String, dynamic>) {
    throw const FormatException('Invalid engine manifest');
  }
  final identity = EngineIdentity.fromJson(data);
  for (final entry in {
    'Pikafish-MacOS-universal': identity.binarySha256,
    'pikafish.nnue': identity.networkSha256,
  }.entries) {
    final file = File('$directory/${entry.key}');
    final size = await file.length();
    if (size < 1 || size > 200 * 1024 * 1024) {
      throw const FormatException('Invalid engine artifact size');
    }
    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString() != entry.value) {
      throw const FormatException('Engine artifact checksum mismatch');
    }
  }
  return EngineIdentity.fromJson({
    ...identity.toJson(),
    'target': '${identity.target}/${Abi.current()}',
  });
}
