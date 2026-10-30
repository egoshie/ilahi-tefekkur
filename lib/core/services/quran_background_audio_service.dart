import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/v42_models.dart';

class QuranAudioPlaybackState {
  final List< LiveAyahItem > playlist;
  final int currentIndex;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  const QuranAudioPlaybackState({
    this.playlist = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  LiveAyahItem? get activeAyah {
    if (currentIndex < 0 || currentIndex >= playlist.length) return null;
    return playlist[currentIndex];
  }

  bool get hasActiveSession => activeAyah != null;

  QuranAudioPlaybackState copyWith({
    List< LiveAyahItem >? playlist,
    int? currentIndex,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    String? errorMessage,
  }) {
    return QuranAudioPlaybackState(
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage,
    );
  }
}

final quranAudioProvider =
    StateNotifierProvider< QuranBackgroundAudioNotifier, QuranAudioPlaybackState >(
        (ref) {
  return QuranBackgroundAudioNotifier();
});

class QuranBackgroundAudioNotifier
    extends StateNotifier< QuranAudioPlaybackState > {
  static const MethodChannel _mediaChannel =
      MethodChannel('com.ilahi.tefekkur/media');

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription< PlayerState >? _playerStateSub;
  StreamSubscription< Duration >? _posSub;
  StreamSubscription< Duration? >? _durSub;
  bool _sessionReady = false;

  QuranBackgroundAudioNotifier() : super(const QuranAudioPlaybackState()) {
    _initAudioEngine();
  }

  Future< void > _initAudioEngine() async {
    _mediaChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'remotePlay':
          await resume();
          break;
        case 'remotePause':
          await pause();
          break;
        case 'remoteNext':
          await skipToNext();
          break;
        case 'remotePrev':
          await skipToPrevious();
          break;
        case 'remoteStop':
          await stop();
          break;
      }
      return true;
    });

    _playerStateSub = _player.playerStateStream.listen((pState) {
      final playing = pState.playing;
      final proc = pState.processingState;

      if (proc == ProcessingState.completed) {
        if (state.currentIndex + 1 < state.playlist.length) {
          playAyahAtIndex(state.currentIndex + 1);
        } else {
          stop();
        }
        return;
      }

      state = state.copyWith(
        isPlaying: playing,
        isLoading: proc == ProcessingState.loading ||
            proc == ProcessingState.buffering,
      );
      _syncIosNowPlayingCenter();
    });

    _posSub = _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _durSub = _player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
        _syncIosNowPlayingCenter();
      }
    });
  }

  Future< void > _ensureBackgroundSession() async {
    if (_sessionReady) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
      _sessionReady = true;
    } catch (_) {}
  }

  Future< void > startSurahPlaylist(
    List< LiveAyahItem > ayahs, {
    int startIndex = 0,
  }) async {
    if (ayahs.isEmpty) return;
    state = state.copyWith(
      playlist: ayahs,
      currentIndex: startIndex.clamp(0, ayahs.length - 1),
      errorMessage: null,
    );
    await playAyahAtIndex(startIndex.clamp(0, ayahs.length - 1));
  }

  Future< void > playAyahAtIndex(int index) async {
    if (index < 0 || index >= state.playlist.length) return;
    await _ensureBackgroundSession();

    final ayah = state.playlist[index];
    state = state.copyWith(
      currentIndex: index,
      isLoading: true,
      errorMessage: null,
    );

    final primaryUrl = ayah.audioUrl.isNotEmpty
        ? ayah.audioUrl
        : 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${ayah.globalNumber}.mp3';

    try {
      await _player.setUrl(primaryUrl);
      await _player.play();
      await _syncIosNowPlayingCenter();
    } catch (_) {
      try {
        final fallbackUrl =
            'https://cdn.islamic.network/quran/audio/64/ar.alafasy/${ayah.globalNumber}.mp3';
        await _player.setUrl(fallbackUrl);
        await _player.play();
        await _syncIosNowPlayingCenter();
      } catch (_) {
        state = state.copyWith(
          isPlaying: false,
          isLoading: false,
          errorMessage: "Tilavet ses akışı için internet bağlantısı gereklidir.",
        );
      }
    }
  }

  Future< void > togglePlayPause() async {
    if (!state.hasActiveSession) return;
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  Future< void > pause() async {
    await _player.pause();
    state = state.copyWith(isPlaying: false);
    await _syncIosNowPlayingCenter();
  }

  Future< void > resume() async {
    await _ensureBackgroundSession();
    await _player.play();
    state = state.copyWith(isPlaying: true);
    await _syncIosNowPlayingCenter();
  }

  Future< void > skipToNext() async {
    if (state.currentIndex + 1 < state.playlist.length) {
      await playAyahAtIndex(state.currentIndex + 1);
    }
  }

  Future< void > skipToPrevious() async {
    if (state.currentIndex - 1 >= 0) {
      await playAyahAtIndex(state.currentIndex - 1);
    } else if (state.hasActiveSession) {
      await _player.seek(Duration.zero);
    }
  }

  Future< void > stop() async {
    await _player.stop();
    state = const QuranAudioPlaybackState();
    try {
      await _mediaChannel.invokeMethod('clearNowPlaying');
    } catch (_) {}
  }

  Future< void > _syncIosNowPlayingCenter() async {
    final ayah = state.activeAyah;
    if (ayah == null) return;
    try {
      await _mediaChannel.invokeMethod('updateNowPlaying', {
        'title': '${ayah.surahNumber}. ${ayah.surahName} • Ayet ${ayah.numberInSurah}',
        'artist': 'Mishary Rashid Al-Afasy',
        'album': 'Huzur • Kur\'ân-ı Kerîm',
        'arabic': ayah.arabicText,
        'isPlaying': _player.playing,
        'durationSeconds': state.duration.inSeconds > 0
            ? state.duration.inSeconds.toDouble()
            : 12.0,
        'elapsedSeconds': state.position.inSeconds.toDouble(),
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
