import 'dart:async';
import 'package:chess_next/ports/text_clipboard.dart';

class MemoryClipboard implements TextClipboard {
  String? text;
  Completer<String?>? readGate;
  Completer<void>? writeGate;
  bool failRead = false, failWrite = false;
  final writes = <String>[];
  @override
  Future<String?> read() async {
    if (failRead) throw StateError('clipboard denied');
    return readGate == null ? text : await readGate!.future;
  }

  @override
  Future<void> write(String value) async {
    writes.add(value);
    await writeGate?.future;
    if (failWrite) throw StateError('clipboard denied');
    text = value;
  }
}
