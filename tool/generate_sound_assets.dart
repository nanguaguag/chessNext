import 'dart:io';
import 'package:chess_next/adapters/audio/tone_wave.dart';

Future<void> main() async {
  final directory = Directory('assets/audio');
  await directory.create(recursive: true);
  await File(
    '${directory.path}/select.wav',
  ).writeAsBytes(toneWave(frequency: 880, durationMs: 45));
  await File(
    '${directory.path}/move.wav',
  ).writeAsBytes(toneWave(frequency: 520, durationMs: 75));
}
