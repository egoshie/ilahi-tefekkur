import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class AmbianceChannel {
  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final bool isPlaying;
  final double volume;
  const AmbianceChannel({required this.id, required this.title, required this.subtitle, required this.assetPath, this.isPlaying = false, this.volume = 0.35});
  AmbianceChannel copyWith({bool? isPlaying, double? volume}) => AmbianceChannel(
    id: id, title: title, subtitle: subtitle, assetPath: assetPath,
    isPlaying: isPlaying ?? this.isPlaying, volume: volume ?? this.volume,
  );
}

class AmbianceMixerNotifier extends StateNotifier<List<AmbianceChannel>> {
  AmbianceMixerNotifier() : super(const [
    AmbianceChannel(id:'rain',title:'Yumuşak Yağmur',subtitle:'Sakin yağmur dokusu',assetPath:'assets/audio/rain.wav'),
    AmbianceChannel(id:'water',title:'Su ve Dere',subtitle:'Akışkan su ambiyansı',assetPath:'assets/audio/water.wav'),
    AmbianceChannel(id:'ney',title:'Ney Esintisi',subtitle:'Düşük tempolu özgün ton',assetPath:'assets/audio/ney.wav'),
    AmbianceChannel(id:'wind',title:'Gece Esintisi',subtitle:'Hafif rüzgâr dokusu',assetPath:'assets/audio/wind.wav'),
  ]);
  final Map<String, AudioPlayer> _players = {};

  Future<void> toggleChannel(String id) async {
    final index = state.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final channel = state[index];
    final player = _players.putIfAbsent(id, () => AudioPlayer());
    try {
      if (channel.isPlaying) {
        await player.stop();
        state = [for (final item in state) item.id == id ? item.copyWith(isPlaying: false) : item];
      } else {
        await player.setAsset(channel.assetPath);
        await player.setLoopMode(LoopMode.one);
        await player.setVolume(channel.volume.clamp(0.0, 1.0).toDouble());
        state = [for (final item in state) item.id == id ? item.copyWith(isPlaying: true) : item];
        unawaited(player.play());
      }
    } catch (_) {
      state = [for (final item in state) item.id == id ? item.copyWith(isPlaying: false) : item];
    }
  }

  Future<void> setVolume(String id, double volume) async {
    final safeVolume = volume.clamp(0.0, 1.0).toDouble();
    state = [for (final item in state) item.id == id ? item.copyWith(volume: safeVolume) : item];
    await _players[id]?.setVolume(safeVolume);
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    super.dispose();
  }
}

final ambianceMixerProvider = StateNotifierProvider<AmbianceMixerNotifier, List<AmbianceChannel>>((ref) => AmbianceMixerNotifier());
