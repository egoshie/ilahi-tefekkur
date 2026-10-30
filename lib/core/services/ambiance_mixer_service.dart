import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class AmbianceChannel {
  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final bool isPlaying;
  final double volume;

  const AmbianceChannel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    this.isPlaying = false,
    this.volume = 0.70,
  });

  AmbianceChannel copyWith({bool? isPlaying, double? volume}) {
    return AmbianceChannel(
      id: id,
      title: title,
      subtitle: subtitle,
      assetPath: assetPath,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
    );
  }
}

final ambianceMixerProvider =
    StateNotifierProvider< AmbianceMixerNotifier, List< AmbianceChannel > >((ref) {
  return AmbianceMixerNotifier();
});

class AmbianceMixerNotifier extends StateNotifier< List< AmbianceChannel > > {
  final Map< String, AudioPlayer > _players = {};
  bool _sessionConfigured = false;

  AmbianceMixerNotifier()
      : super(const [
          AmbianceChannel(
            id: 'ney',
            title: 'Ney & Huzur Frekansı (432Hz)',
            subtitle: 'Çevrimdışı harmonik odaklanma akustiği',
            assetPath: 'assets/audio/ney.wav',
          ),
          AmbianceChannel(
            id: 'rain',
            title: 'Seher Yağmuru',
            subtitle: 'Çevrimdışı yumuşak yağmur damlası dokusu',
            assetPath: 'assets/audio/rain.wav',
          ),
          AmbianceChannel(
            id: 'water',
            title: 'Dingin Su Akışı',
            subtitle: 'Çevrimdışı su dalgası ve kubbe rezonansı',
            assetPath: 'assets/audio/water.wav',
          ),
          AmbianceChannel(
            id: 'wind',
            title: 'Gece Esintisi',
            subtitle: 'Çevrimdışı hafif ufuk rüzgarı',
            assetPath: 'assets/audio/wind.wav',
          ),
        ]);

  Future< void > _ensureAudioSession() async {
    if (_sessionConfigured) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _sessionConfigured = true;
  }

  Future< void > toggleChannel(String id) async {
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
      await player.setAsset(channel.assetPath);
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(channel.volume);
      await player.play();

      state = [
        for (final c in state)
          if (c.id == id) c.copyWith(isPlaying: true) else c,
      ];
    }
  }

  Future< void > setVolume(String id, double vol) async {
    final clamped = vol.clamp(0.0, 1.0);
    await _players[id]?.setVolume(clamped);
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(volume: clamped) else c,
    ];
  }

  Future< void > stopAll() async {
    for (final p in _players.values) {
      await p.stop();
    }
    state = [
      for (final c in state) c.copyWith(isPlaying: false),
    ];
  }

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    super.dispose();
  }
}
