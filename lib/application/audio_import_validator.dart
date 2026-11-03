import 'dart:typed_data';

import '../ports/audio_library.dart';

/// Strict bounded WAV/MP3 metadata validation for user-selected offline audio.
abstract final class AudioImportValidator {
  static const maxBytes = AudioLibraryLimits.maxBytes;
  static const maxDurationMs = 5000;

  static int validate(SelectedAudioFile file) {
    if (file.bytes.length > maxBytes) {
      throw const AudioLibraryException(AudioLibraryFailure.tooLarge);
    }
    final duration = switch (file.extension.toLowerCase()) {
      'wav' => _wavDuration(file.bytes),
      'mp3' => _mp3Duration(file.bytes),
      _ => null,
    };
    if (duration == null) {
      throw const AudioLibraryException(AudioLibraryFailure.format);
    }
    if (duration > maxDurationMs) {
      throw const AudioLibraryException(AudioLibraryFailure.duration);
    }
    return duration;
  }

  static int? _wavDuration(Uint8List bytes) {
    if (bytes.length < 44 ||
        !_ascii(bytes, 0, 'RIFF') ||
        !_ascii(bytes, 8, 'WAVE')) {
      return null;
    }
    final data = ByteData.sublistView(bytes);
    final riffEnd = data.getUint32(4, Endian.little) + 8;
    if (riffEnd > bytes.length || riffEnd < 12) return null;
    int? byteRate;
    int? dataSize;
    var offset = 12;
    while (offset + 8 <= riffEnd) {
      final size = data.getUint32(offset + 4, Endian.little);
      final body = offset + 8;
      if (size > riffEnd - body) return null;
      if (_ascii(bytes, offset, 'fmt ') && size >= 16) {
        final format = data.getUint16(body, Endian.little);
        final channels = data.getUint16(body + 2, Endian.little);
        final sampleRate = data.getUint32(body + 4, Endian.little);
        byteRate = data.getUint32(body + 8, Endian.little);
        final blockAlign = data.getUint16(body + 12, Endian.little);
        final bits = data.getUint16(body + 14, Endian.little);
        if ((format != 1 && format != 3) ||
            channels < 1 ||
            channels > 2 ||
            sampleRate < 8000 ||
            sampleRate > 192000 ||
            byteRate == 0 ||
            blockAlign == 0 ||
            bits == 0) {
          return null;
        }
      } else if (_ascii(bytes, offset, 'data')) {
        dataSize = size;
      }
      offset = body + size + (size.isOdd ? 1 : 0);
    }
    if (byteRate == null || dataSize == null || dataSize == 0) return null;
    return (dataSize * 1000 / byteRate).ceil();
  }

  static int? _mp3Duration(Uint8List bytes) {
    var offset = 0;
    if (bytes.length >= 10 && _ascii(bytes, 0, 'ID3')) {
      final flags = bytes[5];
      final tagSize =
          ((bytes[6] & 0x7f) << 21) |
          ((bytes[7] & 0x7f) << 14) |
          ((bytes[8] & 0x7f) << 7) |
          (bytes[9] & 0x7f);
      offset = 10 + tagSize + ((flags & 0x10) != 0 ? 10 : 0);
      if (offset > bytes.length) return null;
    }
    var samples = 0;
    var sampleRate = 0;
    var frames = 0;
    while (offset + 4 <= bytes.length) {
      if (_ascii(bytes, offset, 'TAG')) break; // ID3v1 footer.
      final header =
          (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
      if (((header >> 21) & 0x7ff) != 0x7ff) return null;
      final version = (header >> 19) & 0x3;
      final layer = (header >> 17) & 0x3;
      final bitrateIndex = (header >> 12) & 0xf;
      final rateIndex = (header >> 10) & 0x3;
      final padding = (header >> 9) & 1;
      if (version == 1 ||
          layer != 1 ||
          bitrateIndex == 0 ||
          bitrateIndex == 15 ||
          rateIndex == 3) {
        return null;
      }
      const mpeg1Layer3 = [
        0,
        32,
        40,
        48,
        56,
        64,
        80,
        96,
        112,
        128,
        160,
        192,
        224,
        256,
        320,
      ];
      const mpeg2Layer3 = [
        0,
        8,
        16,
        24,
        32,
        40,
        48,
        56,
        64,
        80,
        96,
        112,
        128,
        144,
        160,
      ];
      const rates = [44100, 48000, 32000];
      final baseRate = rates[rateIndex];
      final rate = switch (version) {
        3 => baseRate,
        2 => baseRate ~/ 2,
        _ => baseRate ~/ 4,
      };
      final bitrate =
          (version == 3 ? mpeg1Layer3 : mpeg2Layer3)[bitrateIndex] * 1000;
      final frameLength =
          ((version == 3 ? 144 : 72) * bitrate ~/ rate) + padding;
      if (frameLength < 4 || frameLength > bytes.length - offset) return null;
      sampleRate = rate;
      samples += version == 3 ? 1152 : 576;
      frames++;
      offset += frameLength;
    }
    if (frames == 0 || sampleRate == 0) return null;
    return (samples * 1000 / sampleRate).ceil();
  }

  static bool _ascii(Uint8List bytes, int offset, String value) {
    if (offset < 0 || offset + value.length > bytes.length) return false;
    for (var i = 0; i < value.length; i++) {
      if (bytes[offset + i] != value.codeUnitAt(i)) return false;
    }
    return true;
  }
}
