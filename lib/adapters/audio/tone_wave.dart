import 'dart:math' as math;
import 'dart:typed_data';

/// Reproducible original mono PCM tone, avoiding third-party sound assets.
Uint8List toneWave({required int frequency, required int durationMs}) {
  const sampleRate = 22050;
  final sampleCount = sampleRate * durationMs ~/ 1000;
  final dataLength = sampleCount;
  final bytes = Uint8List(44 + dataLength);
  final view = ByteData.sublistView(bytes);
  void ascii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes[offset + i] = value.codeUnitAt(i);
    }
  }

  ascii(0, 'RIFF');
  view.setUint32(4, 36 + dataLength, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  view.setUint32(16, 16, Endian.little);
  view.setUint16(20, 1, Endian.little);
  view.setUint16(22, 1, Endian.little);
  view.setUint32(24, sampleRate, Endian.little);
  view.setUint32(28, sampleRate, Endian.little);
  view.setUint16(32, 1, Endian.little);
  view.setUint16(34, 8, Endian.little);
  ascii(36, 'data');
  view.setUint32(40, dataLength, Endian.little);
  for (var i = 0; i < sampleCount; i++) {
    final phase = 2 * math.pi * frequency * i / sampleRate;
    final edge = math.min(1.0, math.min(i / 110, (sampleCount - i) / 220));
    final sample = 128 + (52 * edge * math.sin(phase)).round();
    bytes[44 + i] = sample.clamp(0, 255);
  }
  return bytes;
}
