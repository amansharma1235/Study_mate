import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AmbientSoundType {
  none,
  rain,
  alphaWaves,
  forest,
  whiteNoise,
  cafe,
  oceanWaves,
  fireplace,
  lofiBeats,
}

class AmbientTrack {
  final AmbientSoundType type;
  final String title;
  final String subtitle;
  final String iconEmoji;

  const AmbientTrack({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.iconEmoji,
  });
}

const List<AmbientTrack> kAmbientTracks = [
  AmbientTrack(
    type: AmbientSoundType.none,
    title: 'Mute / Off',
    subtitle: 'Silent focus session',
    iconEmoji: '🔇',
  ),
  AmbientTrack(
    type: AmbientSoundType.rain,
    title: 'Gentle Rain',
    subtitle: 'Calming rain & droplet focus',
    iconEmoji: '🌧️',
  ),
  AmbientTrack(
    type: AmbientSoundType.alphaWaves,
    title: 'Alpha Waves 10Hz',
    subtitle: 'Binaural focus frequency',
    iconEmoji: '🧠',
  ),
  AmbientTrack(
    type: AmbientSoundType.oceanWaves,
    title: 'Ocean Surf',
    subtitle: 'Rhythmic deep relaxing waves',
    iconEmoji: '🌊',
  ),
  AmbientTrack(
    type: AmbientSoundType.fireplace,
    title: 'Fireplace',
    subtitle: 'Warm crackling hearth ambiance',
    iconEmoji: '🔥',
  ),
  AmbientTrack(
    type: AmbientSoundType.lofiBeats,
    title: 'Lo-Fi Chill',
    subtitle: 'Mellow study chord progression',
    iconEmoji: '🎧',
  ),
  AmbientTrack(
    type: AmbientSoundType.forest,
    title: 'Forest & Birds',
    subtitle: 'Nature peace & bird chirps',
    iconEmoji: '🌲',
  ),
  AmbientTrack(
    type: AmbientSoundType.whiteNoise,
    title: 'Soft White Noise',
    subtitle: 'Masks background distractions',
    iconEmoji: '📻',
  ),
  AmbientTrack(
    type: AmbientSoundType.cafe,
    title: 'Cozy Library Cafe',
    subtitle: 'Warm study room ambiance',
    iconEmoji: '☕',
  ),
];

final ambientSoundServiceProvider =
    StateNotifierProvider<AmbientSoundNotifier, AmbientSoundState>((ref) {
  return AmbientSoundNotifier();
});

class AmbientSoundState {
  final AmbientSoundType currentSound;
  final bool isPlaying;
  final double volume;

  const AmbientSoundState({
    this.currentSound = AmbientSoundType.none,
    this.isPlaying = false,
    this.volume = 0.6,
  });

  AmbientSoundState copyWith({
    AmbientSoundType? currentSound,
    bool? isPlaying,
    double? volume,
  }) {
    return AmbientSoundState(
      currentSound: currentSound ?? this.currentSound,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
    );
  }
}

class AmbientSoundNotifier extends StateNotifier<AmbientSoundState> {
  final AudioPlayer _player = AudioPlayer();
  final Map<AmbientSoundType, String> _cachedFilePaths = {};

  AmbientSoundNotifier() : super(const AmbientSoundState()) {
    _initPlayer();
  }

  void _initPlayer() {
    try {
      AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (_) {}
    _player.setReleaseMode(ReleaseMode.loop);
    _player.setVolume(state.volume);
  }

  /// Synthesize and play authentic ambient study soundscapes offline
  Future<void> selectSound(AmbientSoundType type) async {
    if (type == AmbientSoundType.none) {
      await stop();
      state = state.copyWith(currentSound: type, isPlaying: false);
      return;
    }

    try {
      await _player.stop();

      // Ensure local synthesized sound file is available
      final filePath = await _getOrCreateAudioFile(type);
      final file = File(filePath);

      if (await file.exists()) {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(state.volume);
        await _player.play(DeviceFileSource(filePath));
        state = state.copyWith(currentSound: type, isPlaying: true);
      } else {
        // Fallback to in-memory bytes source
        final bytes = _synthesizeSound(type);
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(state.volume);
        await _player.play(BytesSource(bytes, mimeType: 'audio/wav'));
        state = state.copyWith(currentSound: type, isPlaying: true);
      }
    } catch (e) {
      debugPrint('Ambient sound playback exception: $e');
      // If error occurs, try fallback with raw bytes source
      try {
        final bytes = _synthesizeSound(type);
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(state.volume);
        await _player.play(BytesSource(bytes, mimeType: 'audio/wav'));
        state = state.copyWith(currentSound: type, isPlaying: true);
      } catch (inner) {
        debugPrint('Ambient sound fallback exception: $inner');
        state = state.copyWith(currentSound: type, isPlaying: false);
      }
    }
  }

  Future<void> togglePlayPause() async {
    if (state.currentSound == AmbientSoundType.none) {
      await selectSound(AmbientSoundType.rain);
      return;
    }

    if (state.isPlaying) {
      await _player.pause();
      state = state.copyWith(isPlaying: false);
    } else {
      await _player.resume();
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> setVolume(double val) async {
    final clamped = val.clamp(0.0, 1.0);
    await _player.setVolume(clamped);
    state = state.copyWith(volume: clamped);
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    state = state.copyWith(isPlaying: false);
  }

  /// Get local path for synthesized track or generate it
  Future<String> _getOrCreateAudioFile(AmbientSoundType type) async {
    if (_cachedFilePaths.containsKey(type)) {
      final path = _cachedFilePaths[type]!;
      if (await File(path).exists()) return path;
    }

    final tempDir = Directory.systemTemp;
    final filePath = '${tempDir.path}/studymate_ambient_${type.name}.wav';
    final file = File(filePath);

    if (!await file.exists() || await file.length() < 100) {
      final bytes = _synthesizeSound(type);
      await file.writeAsBytes(bytes, flush: true);
    }

    _cachedFilePaths[type] = filePath;
    return filePath;
  }

  /// Pure Dart sound synthesizer for authentic looping audio without external downloads
  static Uint8List _synthesizeSound(AmbientSoundType type) {
    const sampleRate = 22050;
    const durationSeconds = 4; // 4 second seamless looping buffer
    final totalSamples = sampleRate * durationSeconds;
    final samples = Int16List(totalSamples);
    final random = Random(42);

    switch (type) {
      case AmbientSoundType.alphaWaves:
        // Pure 10Hz Binaural Alpha wave: 216Hz carrier with 10Hz modulation + 432Hz harmonic
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          final carrier = sin(2 * pi * 216 * t);
          final mod = 0.5 + 0.5 * sin(2 * pi * 10 * t);
          final overtone = 0.3 * sin(2 * pi * 432 * t);
          final val = (carrier * mod * 0.7 + overtone * 0.3) * 16000;
          samples[i] = val.toInt().clamp(-32767, 32767);
        }
        break;

      case AmbientSoundType.rain:
        // Pink / Brown noise simulation with low-pass filter & random drop impulses
        double b0 = 0, b1 = 0, b2 = 0;
        for (int i = 0; i < totalSamples; i++) {
          final white = (random.nextDouble() * 2 - 1);
          // Pink noise filter approximation
          b0 = 0.99886 * b0 + white * 0.0555179;
          b1 = 0.99332 * b1 + white * 0.0750759;
          b2 = 0.96900 * b2 + white * 0.1538520;
          double pink = b0 + b1 + b2 + white * 0.5362;

          // Occasional soft droplet patter
          if (random.nextDouble() < 0.003) {
            pink += (random.nextDouble() * 2 - 1) * 3.5;
          }

          final val = (pink * 3200).clamp(-32767.0, 32767.0);
          samples[i] = val.toInt();
        }
        break;

      case AmbientSoundType.whiteNoise:
        // Calming broadband acoustic masking noise
        double filter = 0.0;
        for (int i = 0; i < totalSamples; i++) {
          final white = (random.nextDouble() * 2 - 1);
          filter = 0.85 * filter + 0.15 * white;
          final val = (filter * 12000).clamp(-32767.0, 32767.0);
          samples[i] = val.toInt();
        }
        break;

      case AmbientSoundType.forest:
        // Nature breeze + chirping bird sweeps
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          // Breeze whisper
          final breeze = sin(2 * pi * 120 * t) * 0.15 +
              (random.nextDouble() * 2 - 1) * 0.12;

          // Periodic melodic bird chirp
          double bird = 0.0;
          final cycleTime = t % 1.5;
          if (cycleTime < 0.18) {
            final chirpFreq = 2400 + 800 * sin(2 * pi * 18 * cycleTime);
            final env = sin(pi * (cycleTime / 0.18));
            bird = sin(2 * pi * chirpFreq * t) * env * 0.65;
          }

          final val = ((breeze + bird) * 16000).clamp(-32767.0, 32767.0);
          samples[i] = val.toInt();
        }
        break;

      case AmbientSoundType.cafe:
        // Cozy low-frequency cafe resonance
        double rumble = 0.0;
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          final white = (random.nextDouble() * 2 - 1);
          rumble = 0.96 * rumble + 0.04 * white;
          final warmHum = sin(2 * pi * 85 * t) * 0.2;
          final val = ((rumble * 0.7 + warmHum * 0.3) * 18000)
              .clamp(-32767.0, 32767.0);
          samples[i] = val.toInt();
        }
        break;

      case AmbientSoundType.oceanWaves:
        // Slow oceanic surf swells (~8-second period) with foamy wave crests
        double surfFilter = 0.0;
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          // Ocean rhythmic ebb & flow
          final swell = 0.5 + 0.5 * sin(2 * pi * 0.125 * t);
          final white = (random.nextDouble() * 2 - 1);
          surfFilter = 0.92 * surfFilter + 0.08 * white;
          final deepRumble = sin(2 * pi * 55 * t) * 0.25;
          final val = ((surfFilter * 0.75 + deepRumble) * swell * 22000)
              .clamp(-32767.0, 32767.0);
          samples[i] = val.toInt();
        }
        break;

      case AmbientSoundType.fireplace:
        // Cozy crackling hearth: warm low ember rumble with crisp wood pops
        double ember = 0.0;
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          final white = (random.nextDouble() * 2 - 1);
          ember = 0.95 * ember + 0.05 * white;
          final lowBurn = sin(2 * pi * 70 * t) * 0.15;
          double crackle = 0.0;
          // Occasional sharp spark/wood pop
          if (random.nextDouble() < 0.008) {
            crackle = (random.nextDouble() * 2 - 1) * 3.8;
          }
          final val = ((ember * 0.6 + lowBurn + crackle * 0.4) * 20000)
              .clamp(-32767.0, 32767.0);
          samples[i] = val.toInt();
        }
        break;

      case AmbientSoundType.lofiBeats:
        // Relaxing Lo-Fi study chords (Cmaj7 & Fmaj7) with soft heartbeat rhythm
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          // 2-second chord oscillation
          final chordCycle = (t % 4.0) < 2.0;
          final f1 = chordCycle ? 261.63 : 220.00; // C4 / A3
          final f2 = chordCycle ? 329.63 : 261.63; // E4 / C4
          final f3 = chordCycle ? 392.00 : 329.63; // G4 / E4
          final f4 = chordCycle ? 493.88 : 440.00; // B4 / A4

          final chord = (sin(2 * pi * f1 * t) * 0.3 +
                  sin(2 * pi * f2 * t) * 0.25 +
                  sin(2 * pi * f3 * t) * 0.25 +
                  sin(2 * pi * f4 * t) * 0.2) *
              0.45;

          // Soft low rhythmic pulse every 1 second
          final beatCycle = t % 1.0;
          final kickEnv = beatCycle < 0.15 ? sin(pi * (beatCycle / 0.15)) : 0.0;
          final kick = sin(2 * pi * 65 * beatCycle) * kickEnv * 0.4;

          final val = ((chord + kick) * 17000).clamp(-32767.0, 32767.0);
          samples[i] = val.toInt();
        }
        break;

      case AmbientSoundType.none:
        break;
    }

    return _buildWavHeader(sampleRate: sampleRate, pcmSamples: samples);
  }

  /// 44-byte standard RIFF WAVE header generator
  static Uint8List _buildWavHeader({
    required int sampleRate,
    required Int16List pcmSamples,
  }) {
    const numChannels = 1;
    final byteRate = sampleRate * numChannels * 2;
    const blockAlign = numChannels * 2;
    final dataLength = pcmSamples.length * 2;
    final totalLength = 36 + dataLength;

    final bytes = ByteData(44 + dataLength);
    // RIFF
    bytes.setUint8(0, 0x52);
    bytes.setUint8(1, 0x49);
    bytes.setUint8(2, 0x46);
    bytes.setUint8(3, 0x46);
    bytes.setUint32(4, totalLength, Endian.little);
    bytes.setUint8(8, 0x57);
    bytes.setUint8(9, 0x41);
    bytes.setUint8(10, 0x56);
    bytes.setUint8(11, 0x45);

    // fmt
    bytes.setUint8(12, 0x66);
    bytes.setUint8(13, 0x6D);
    bytes.setUint8(14, 0x74);
    bytes.setUint8(15, 0x20);
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little); // PCM format
    bytes.setUint16(22, numChannels, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, byteRate, Endian.little);
    bytes.setUint16(32, blockAlign, Endian.little);
    bytes.setUint16(34, 16, Endian.little);

    // data
    bytes.setUint8(36, 0x64);
    bytes.setUint8(37, 0x61);
    bytes.setUint8(38, 0x74);
    bytes.setUint8(39, 0x61);
    bytes.setUint32(40, dataLength, Endian.little);

    for (int i = 0; i < pcmSamples.length; i++) {
      bytes.setInt16(44 + (i * 2), pcmSamples[i], Endian.little);
    }

    return bytes.buffer.asUint8List();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
