abstract interface class TextClipboard {
  Future<String?> read();
  Future<void> write(String text);
}
