import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AmbianceChannel {
  final String id;
  final String title;
  final String subtitle;
  final double baseFreq;
  final bool isPlaying;
  final double volume;

  const AmbianceChannel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.baseFreq,
    this.isPlaying = false,
    this.volume = 0.75,
  });

  AmbianceChannel copyWith({bool? isPlaying, double? volume}) {
    return AmbianceChannel(
      id: id,
      title: title,
      subtitle: subtitle,
      baseFreq: baseFreq,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
    );
  }
}

final ambianceMixerProvider =
    StateNotifierProvider<AmbianceMixerNotifier, List<AmbianceChannel>>((ref) {
  return AmbianceMixerNotifier();
});

class AmbianceMixerNotifier extends StateNotifier<List<AmbianceChannel>> {
  final Map<String, AudioPlayer> _players = {};
  bool _sessionConfigured = false;

  AmbianceMixerNotifier()
      : super(const [
          AmbianceChannel(
            id: 'ney_432',
            title: '432Hz Hicaz & Ney Tefekkür Frekansı',
            subtitle: 'Harmonik nefes ve ruhani odaklanma tınısı',
            baseFreq: 216.0,
          ),
          AmbianceChannel(
            id: 'rain_night',
            title: 'Seher Yağmuru & Su Akustik Dokusu',
            subtitle: 'Yumuşak yağmur damlaları ve dinginlik',
            baseFreq: 164.0,
          ),
          AmbianceChannel(
            id: 'kaaba_hum',
            title: 'Kubbe Rezonansı & Harem Akustiği',
            subtitle: 'Derin 108Hz meditatif kubbe yankısı',
            baseFreq: 108.0,
          ),
          AmbianceChannel(
            id: 'desert_wind',
            title: 'Gece Çöl Rüzgarı & Sina Esintisi',
            subtitle: 'Ufuk frekansı ve hafif rüzgar uğultusu',
            baseFreq: 144.0,
          ),
        ]);

  Future<void> _ensureAudioSession() async {
    if (_sessionConfigured) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _sessionConfigured = true;
  }

  Future<void> toggleChannel(String id) async {
    await _ensureAudioSession();
    final index = state.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final channel = state[index];

    if (channel.isPlaying) {
      await _players[id]?.stop();
      state = [
        for (final c in state)
          if (c.id == id) c.copyWith(isPlaying: false) else c,
      ];
    } else {
      final player = _players.putIfAbsent(id, () => AudioPlayer());
      final wavFile = await _ensureSynthesizedWavFile(channel.id, channel.baseFreq);
      await player.setFilePath(wavFile.path);
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(channel.volume);
      player.play();

      state = [
        for (final c in state)
          if (c.id == id) c.copyWith(isPlaying: true) else c,
      ];
    }
  }

  Future<void> setVolume(String id, double vol) async {
    await _players[id]?.setVolume(vol);
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(volume: vol) else c,
    ];
  }

  Future<File> _ensureSynthesizedWavFile(String mode, double freq) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/synth_v2_$mode.wav');
    if (await file.exists() && await file.length() > 1000) {
      return file;
    }
    final bytes = _buildRichAcousticWav(freq, mode);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Uint8List _buildRichAcousticWav(double freq, String mode) {
    const sampleRate = 22050;
    const seconds = 8;
    const numSamples = sampleRate * seconds;
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    const riff = [0x52, 0x49, 0x46, 0x46];
    const wave = [0x57, 0x41, 0x56, 0x45];
    const fmt = [0x66, 0x6D, 0x74, 0x20];
    const dataHeader = [0x64, 0x61, 0x74, 0x61];

    for (int i = 0; i < 4; i++) {
      buffer.setUint8(i, riff[i]);
      buffer.setUint8(8 + i, wave[i]);
      buffer.setUint8(12 + i, fmt[i]);
      buffer.setUint8(36 + i, dataHeader[i]);
    }
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    buffer.setUint32(40, dataSize, Endian.little);

    final rng = math.Random(mode.hashCode);
    double lpFilter = 0.0;
    double brown = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      double fade = 1.0;
      if (t < 0.4) fade = t / 0.4;
      if (t > seconds - 0.4) fade = (seconds - t) / 0.4;

      final breathMod = 0.75 + 0.25 * math.sin(2 * math.pi * 0.25 * t);
      final white = rng.nextDouble() * 2.0 - 1.0;
      brown = (brown + (0.02 * white)) / 1.02;
      lpFilter = lpFilter * 0.92 + white * 0.08;

      double signal = 0.0;
      if (mode == 'ney_432') {
        final vibrato = math.sin(2 * math.pi * 4.5 * t) * 1.2;
        final f = freq + vibrato;
        signal = math.sin(2 * math.pi * f * t) * 0.35 +
            math.sin(2 * math.pi * (f * 2.0) * t) * 0.16 +
            math.sin(2 * math.pi * (f * 1.498) * t) * 0.12 +
            lpFilter * 0.08;
      } else if (mode == 'rain_night') {
        final droplet = (rng.nextDouble() > 0.996) ? math.sin(2 * math.pi * 1200 * t) * 0.35 : 0.0;
        signal = lpFilter * 0.55 + brown * 0.45 + droplet;
      } else if (mode == 'kaaba_hum') {
        signal = math.sin(2 * math.pi * freq * t) * 0.38 +
            math.sin(2 * math.pi * (freq * 1.5) * t) * 0.22 +
            math.sin(2 * math.pi * (freq * 0.5) * t) * 0.25 +
            brown * 0.15;
      } else {
        final sweep = 0.5 + 0.5 * math.sin(2 * math.pi * 0.15 * t);
        signal = (brown * 0.7 + lpFilter * 0.3 * sweep) +
            math.sin(2 * math.pi * freq * t) * 0.18;
      }

      final pcm = (signal * breathMod * fade * 18500).clamp(-32760.0, 32760.0).toInt();
      buffer.setInt16(44 + i * 2, pcm, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    super.dispose();
  }
}
