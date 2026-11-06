import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/v42_models.dart';
import 'pricing_and_premium_service.dart';

enum QuranRepeatMode { off, ayah, surah }

class QuranAudioPlaybackState {
  final List<LiveAyahItem> playlist;
  final int currentIndex;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final String? errorMessage;
  final int completedSurahCount;
  final QuranRepeatMode repeatMode;
  final double playbackSpeed;
  final int? sleepTimerMinutes;

  const QuranAudioPlaybackState({
    this.playlist = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
    this.completedSurahCount = 0,
    this.repeatMode = QuranRepeatMode.off,
    this.playbackSpeed = 1.0,
    this.sleepTimerMinutes,
  });

  LiveAyahItem? get activeAyah {
    if (currentIndex < 0 || currentIndex >= playlist.length) return null;
    return playlist[currentIndex];
  }

  bool get hasActiveSession => activeAyah != null;

  QuranAudioPlaybackState copyWith({
    List<LiveAyahItem>? playlist,
    int? currentIndex,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    int? completedSurahCount,
    QuranRepeatMode? repeatMode,
    double? playbackSpeed,
    int? sleepTimerMinutes,
    bool clearSleepTimer = false,
  }) {
    return QuranAudioPlaybackState(
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage,
      completedSurahCount: completedSurahCount ?? this.completedSurahCount,
      repeatMode: repeatMode ?? this.repeatMode,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      sleepTimerMinutes: clearSleepTimer
          ? null
          : (sleepTimerMinutes ?? this.sleepTimerMinutes),
    );
  }
}

final quranAudioProvider = StateNotifierProvider<QuranBackgroundAudioNotifier,
    QuranAudioPlaybackState>((ref) {
  final premiumNotifier = ref.read(premiumServiceProvider.notifier);
  return QuranBackgroundAudioNotifier(
    isPremium: premiumNotifier.ensurePremiumAccess,
  );
});

class QuranBackgroundAudioNotifier
    extends StateNotifier<QuranAudioPlaybackState> {
  static const int freeSurahPlaybackLimit = 3;

  static bool canStartPlaylist({
    required bool isPremium,
    required int completedSurahCount,
  }) {
    return isPremium || completedSurahCount < freeSurahPlaybackLimit;
  }

  static const MethodChannel _mediaChannel =
      MethodChannel('com.ilahi.tefekkur/media');

  final Future<bool> Function() _isPremium;
  final AudioPlayer _player = AudioPlayer();
  Timer? _sleepTimer;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  bool _sessionReady = false;
  bool _completionRecordedForPlaylist = false;
  bool _playbackCountLoaded = false;
  static const String _completedSurahsKey = 'huzur_completed_surah_plays_v1';

  QuranBackgroundAudioNotifier({
    Future<bool> Function()? isPremium,
  })  : _isPremium = isPremium ?? (() async => false),
        super(const QuranAudioPlaybackState()) {
    ensurePlaybackCountLoaded();
    _initAudioEngine();
  }

  Future<void> ensurePlaybackCountLoaded() async {
    if (_playbackCountLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      completedSurahCount: prefs.getInt(_completedSurahsKey) ?? 0,
    );
    _playbackCountLoaded = true;
  }

  Future<void> _recordCompletedSurah() async {
    if (_completionRecordedForPlaylist || state.playlist.isEmpty) return;

    _completionRecordedForPlaylist = true;
    await ensurePlaybackCountLoaded();

    final nextCount = state.completedSurahCount + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_completedSurahsKey, nextCount);

    state = state.copyWith(completedSurahCount: nextCount);
  }

  Future<void> _initAudioEngine() async {
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
        _handlePlaybackCompleted();
        return;
      }

      state = state.copyWith(
        isPlaying: playing,
        isLoading: proc == ProcessingState.loading ||
            proc == ProcessingState.buffering,
      );
      _syncIosNowPlayingCenter();
    });

    _indexSub = _player.currentIndexStream.listen((idx) {
      if (idx != null && idx >= 0 && idx < state.playlist.length) {
        state = state.copyWith(
          currentIndex: idx,
        );
        _syncIosNowPlayingCenter();
      }
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

  Future<void> _handlePlaybackCompleted() async {
    if (state.repeatMode == QuranRepeatMode.ayah) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }

    if (state.currentIndex + 1 < state.playlist.length) {
      await playAyahAtIndex(state.currentIndex + 1);
      return;
    }

    if (state.repeatMode == QuranRepeatMode.surah) {
      await playAyahAtIndex(0);
      return;
    }

    await _recordCompletedSurah();
    await stop();
  }

  Future<void> _ensureBackgroundSession() async {
    if (_sessionReady) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
      _sessionReady = true;
    } catch (_) {}
  }

  Future<bool> startSurahPlaylist(
    List<LiveAyahItem> ayahs, {
    int startIndex = 0,
  }) async {
    if (ayahs.isEmpty) return false;

    await ensurePlaybackCountLoaded();
    final hasPremium = await _isPremium();

    if (!canStartPlaylist(
      isPremium: hasPremium,
      completedSurahCount: state.completedSurahCount,
    )) {
      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        errorMessage: 'Ücretsiz dinleme hakkınız doldu. '
            'Huzur Özel ile sınırsız Kur’an ayeti dinleyebilirsiniz.',
      );
      return false;
    }

    _completionRecordedForPlaylist = false;
    state = state.copyWith(
      playlist: ayahs,
      currentIndex: startIndex.clamp(0, ayahs.length - 1),
      errorMessage: null,
    );

    await playAyahAtIndex(startIndex.clamp(0, ayahs.length - 1));
    return true;
  }

  Future<void> playAyahAtIndex(int index) async {
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
      await _player.setSpeed(state.playbackSpeed);
      await _player.play();
      await _syncIosNowPlayingCenter();
    } catch (_) {
      try {
        final fallbackUrl =
            'https://cdn.islamic.network/quran/audio/64/ar.alafasy/${ayah.globalNumber}.mp3';
        await _player.setUrl(fallbackUrl);
        await _player.setSpeed(state.playbackSpeed);
        await _player.play();
        await _syncIosNowPlayingCenter();
      } catch (_) {
        state = state.copyWith(
          isPlaying: false,
          isLoading: false,
          errorMessage:
              "Tilavet ses akışı için internet bağlantısı gereklidir.",
        );
      }
    }
  }

  Future<void> togglePlayPause() async {
    if (!state.hasActiveSession) return;
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    state = state.copyWith(isPlaying: false);
    await _syncIosNowPlayingCenter();
  }

  Future<void> resume() async {
    await _ensureBackgroundSession();
    await _player.play();
    state = state.copyWith(isPlaying: true);
    await _syncIosNowPlayingCenter();
  }

  Future<void> skipToNext() async {
    if (state.currentIndex + 1 < state.playlist.length) {
      if (_player.hasNext) {
        await _player.seekToNext();
        await _player.play();
      } else {
        await playAyahAtIndex(state.currentIndex + 1);
      }
    }
  }

  Future<void> skipToPrevious() async {
    if (state.currentIndex - 1 >= 0) {
      if (_player.hasPrevious) {
        await _player.seekToPrevious();
        await _player.play();
      } else {
        await playAyahAtIndex(state.currentIndex - 1);
      }
    } else if (state.hasActiveSession) {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> seekTo(Duration position) async {
    if (state.duration <= Duration.zero) return;
    final target = position < Duration.zero
        ? Duration.zero
        : (position > state.duration ? state.duration : position);
    await _player.seek(target);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final safeSpeed = speed.clamp(0.75, 1.5).toDouble();
    await _player.setSpeed(safeSpeed);
    state = state.copyWith(playbackSpeed: safeSpeed);
  }

  void cycleRepeatMode() {
    final next = switch (state.repeatMode) {
      QuranRepeatMode.off => QuranRepeatMode.ayah,
      QuranRepeatMode.ayah => QuranRepeatMode.surah,
      QuranRepeatMode.surah => QuranRepeatMode.off,
    };
    state = state.copyWith(repeatMode: next);
  }

  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    _sleepTimer = null;

    if (minutes == null || minutes <= 0) {
      state = state.copyWith(clearSleepTimer: true);
      return;
    }

    state = state.copyWith(sleepTimerMinutes: minutes);
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      stop();
    });
  }

  Future<void> stop() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    await _player.stop();
    state = QuranAudioPlaybackState(
      completedSurahCount: state.completedSurahCount,
    );
    try {
      await _mediaChannel.invokeMethod('clearNowPlaying');
    } catch (_) {}
  }

  Future<void> _syncIosNowPlayingCenter() async {
    final ayah = state.activeAyah;
    if (ayah == null) return;
    try {
      await _mediaChannel.invokeMethod('updateNowPlaying', {
        'title':
            '${ayah.surahNumber}. ${ayah.surahName} • Ayet ${ayah.numberInSurah}',
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
    _sleepTimer?.cancel();
    _playerStateSub?.cancel();
    _indexSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
