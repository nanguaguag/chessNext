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
  await File(
    '${directory.path}/move2.wav',
  ).writeAsBytes(toneWave(frequency: 390, durationMs: 110));
  await File(
    '${directory.path}/capture.wav',
  ).writeAsBytes(toneWave(frequency: 660, durationMs: 65));
  await File(
    '${directory.path}/check.wav',
  ).writeAsBytes(toneWave(frequency: 740, durationMs: 95));
  await File(
    '${directory.path}/mate.wav',
  ).writeAsBytes(toneWave(frequency: 980, durationMs: 130));
}
