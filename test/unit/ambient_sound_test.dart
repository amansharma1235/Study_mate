import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

Uint8List generateWav({
  required int sampleRate,
  required int numChannels,
  required List<int> pcm16Samples,
}) {
  final byteRate = sampleRate * numChannels * 2;
  final blockAlign = numChannels * 2;
  final dataLength = pcm16Samples.length * 2;
  final totalLength = 36 + dataLength;

  final b = ByteData(44 + dataLength);
  // RIFF header
  b.setUint8(0, 0x52);
  b.setUint8(1, 0x49);
  b.setUint8(2, 0x46);
  b.setUint8(3, 0x46);
  b.setUint32(4, totalLength, Endian.little);
  b.setUint8(8, 0x57);
  b.setUint8(9, 0x41);
  b.setUint8(10, 0x56);
  b.setUint8(11, 0x45);

  // fmt chunk
  b.setUint8(12, 0x66);
  b.setUint8(13, 0x6D);
  b.setUint8(14, 0x74);
  b.setUint8(15, 0x20);
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, numChannels, Endian.little);
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, byteRate, Endian.little);
  b.setUint16(32, blockAlign, Endian.little);
  b.setUint16(34, 16, Endian.little);

  // data chunk
  b.setUint8(36, 0x64);
  b.setUint8(37, 0x61);
  b.setUint8(38, 0x74);
  b.setUint8(39, 0x61);
  b.setUint32(40, dataLength, Endian.little);

  for (int i = 0; i < pcm16Samples.length; i++) {
    b.setInt16(44 + (i * 2), pcm16Samples[i].clamp(-32768, 32767), Endian.little);
  }

  return b.buffer.asUint8List();
}

void main() {
  test('WAV synthesis generates valid header and audio data', () {
    const sampleRate = 22050;
    const durationSec = 1;
    final totalSamples = sampleRate * durationSec;
    final samples = List.generate(totalSamples, (i) {
      final t = i / sampleRate;
      return (sin(2 * pi * 440 * t) * 16000).toInt();
    });

    final bytes = generateWav(
      sampleRate: sampleRate,
      numChannels: 1,
      pcm16Samples: samples,
    );

    expect(bytes.length, equals(44 + totalSamples * 2));
    expect(bytes[0], equals(0x52)); // 'R'
    expect(bytes[1], equals(0x49)); // 'I'
    expect(bytes[2], equals(0x46)); // 'F'
    expect(bytes[3], equals(0x46)); // 'F'
  });
}
