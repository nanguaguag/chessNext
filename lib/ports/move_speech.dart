/// Optional local system speech for a committed Chinese chess move.
abstract interface class MoveSpeechPort {
  Future<void> speak(String notation);
  Future<void> dispose();
}

final class SilentMoveSpeech implements MoveSpeechPort {
  const SilentMoveSpeech();

  @override
  Future<void> speak(String notation) async {}

  @override
  Future<void> dispose() async {}
}
