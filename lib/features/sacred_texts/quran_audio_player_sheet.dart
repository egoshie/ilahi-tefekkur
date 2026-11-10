import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/quran_background_audio_service.dart';

Future<void> showQuranAudioPlayerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const QuranAudioPlayerSheet(),
  );
}

class QuranAudioPlayerSheet extends ConsumerWidget {
  const QuranAudioPlayerSheet({super.key});

  String _time(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = value.inHours;
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  String _repeatLabel(QuranRepeatMode mode) {
    switch (mode) {
      case QuranRepeatMode.off:
        return 'Tekrar kapalı';
      case QuranRepeatMode.ayah:
        return 'Ayet tekrarı';
      case QuranRepeatMode.surah:
        return 'Sure tekrarı';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quranAudioProvider);
    final audio = ref.read(quranAudioProvider.notifier);
    final ayah = state.activeAyah;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF071713),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0x5564FFDA)),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Icon(
                    Icons.graphic_eq_rounded,
                    color: Color(0xFFFFA21A),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'HUZUR • TİLAVET OYNATICISI',
                      style: TextStyle(
                        color: Color(0xFFFFA21A),
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF17634E), Color(0xFF0B2D27)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0x5564FFDA)),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFFFFE082),
                  size: 54,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                ayah?.surahName ?? 'Kur’ân-ı Kerîm',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                ayah == null
                    ? 'Bir sure seçerek tilaveti başlatın'
                    : '${ayah.numberInSurah}. Ayet • Mishary Rashid Al-Afasy',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
              if (ayah != null && ayah.arabicText.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  ayah.arabicText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: Color(0xFFFFEFD0),
                    fontSize: 21,
                    height: 1.8,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Slider(
                value: state.position.inMilliseconds.toDouble().clamp(
                      0.0,
                      state.duration.inMilliseconds > 0
                          ? state.duration.inMilliseconds.toDouble()
                          : 1.0,
                    ),
                min: 0,
                max: state.duration.inMilliseconds > 0
                    ? state.duration.inMilliseconds.toDouble()
                    : 1,
                onChanged: state.duration > Duration.zero
                    ? (value) => audio.seekTo(
                          Duration(milliseconds: value.round()),
                        )
                    : null,
                activeColor: const Color(0xFFFFA21A),
                inactiveColor: Colors.white24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _time(state.position),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    _time(state.duration),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed:
                        state.hasActiveSession ? audio.skipToPrevious : null,
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: 34,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 15),
                  InkWell(
                    onTap:
                        state.hasActiveSession ? audio.togglePlayPause : null,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFA21A),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: const Color(0xFF05231B),
                        size: 39,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  IconButton(
                    onPressed: state.hasActiveSession ? audio.skipToNext : null,
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 34,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 9,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: audio.cycleRepeatMode,
                    icon: const Icon(Icons.repeat_rounded, size: 16),
                    label: Text(_repeatLabel(state.repeatMode)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFA21A),
                      side: const BorderSide(color: Color(0x5564FFDA)),
                    ),
                  ),
                  PopupMenuButton<double>(
                    onSelected: audio.setPlaybackSpeed,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 0.75, child: Text('0.75×')),
                      PopupMenuItem(value: 1.0, child: Text('1.0×')),
                      PopupMenuItem(value: 1.25, child: Text('1.25×')),
                      PopupMenuItem(value: 1.5, child: Text('1.5×')),
                    ],
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.speed_rounded, size: 16),
                      label: Text('${state.playbackSpeed}×'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        disabledForegroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                  PopupMenuButton<int>(
                    onSelected: audio.setSleepTimer,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 15, child: Text('15 dakika')),
                      PopupMenuItem(value: 30, child: Text('30 dakika')),
                      PopupMenuItem(value: 60, child: Text('60 dakika')),
                    ],
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.bedtime_outlined, size: 16),
                      label: Text(
                        state.sleepTimerMinutes == null
                            ? 'Uyku zamanlayıcısı'
                            : '${state.sleepTimerMinutes} dk',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        disabledForegroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                  if (state.sleepTimerMinutes != null)
                    TextButton(
                      onPressed: () => audio.setSleepTimer(null),
                      child: const Text(
                        'Zamanlayıcıyı iptal et',
                        style: TextStyle(color: Color(0xFFFFE082)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
