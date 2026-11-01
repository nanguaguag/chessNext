import 'package:flutter/services.dart';
import '../../ports/text_clipboard.dart';

class FlutterTextClipboard implements TextClipboard {
  @override
  Future<String?> read() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text;
  @override
  Future<void> write(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
