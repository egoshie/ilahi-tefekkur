import 'dart:async';
import 'dart:ui';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/models/app_models.dart';
import '../../core/services/database_seeder.dart';
import '../../core/services/pricing_and_premium_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';
import '../../core/theme/story_share_sheet.dart';
import '../paywall/liquid_glass_paywall.dart';

class SacredTextsScreen extends ConsumerStatefulWidget {
  const SacredTextsScreen({super.key});

  @override
  ConsumerState<SacredTextsScreen> createState() => _SacredTextsScreenState();
}

class _SacredTextsScreenState extends ConsumerState<SacredTextsScreen> {
  String _selectedTab = 'quran';
  List<SurahMeta> _surahs = [];
  SurahMeta? _selectedSurah;
  List<LiveAyahItem> _ayahs = [];
  bool _loadingQuran = false;

  late BibleBookMeta _selectedTorahBook;
  int _selectedTorahChapter = 1;
  List<BibleVerseItem> _torahVerses = [];
  bool _loadingTorah = false;

  late BibleBookMeta _selectedGospelBook;
  int _selectedGospelChapter = 1;
  List<BibleVerseItem> _gospelVerses = [];
  bool _loadingGospel = false;

  final AudioPlayer _quranAudioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  int? _playingAyahIndex;
  final bool _autoAdvanceEnabled = true;

  @override
  void initState() {
    super.initState();
    final torahBooks = DatabaseService.kAllBibleBooks
        .where((b) => b.testament == 'torah')
        .toList();
    final gospelBooks = DatabaseService.kAllBibleBooks
        .where((b) => b.testament == 'gospel')
        .toList();
    _selectedTorahBook = torahBooks.first;
    _selectedGospelBook = gospelBooks.first;

    _setupAudioListener();
    _loadInitialCatalogs();
  }

  Future<void> _setupAudioListener() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _playerSub = _quranAudioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_autoAdvanceEnabled &&
            _playingAyahIndex != null &&
            _playingAyahIndex! + 1 < _ayahs.length) {
          _playAyahAtIndex(_playingAyahIndex! + 1);
        } else {
          if (mounted) {
            setState(() => _playingAyahIndex = null);
          }
        }
      }
    });
  }

  Future<void> _loadInitialCatalogs() async {
    setState(() => _loadingQuran = true);
    final db = ref.read(databaseServiceProvider);
    final surahs = await db.fetchAllSurahs();
    if (mounted) {
      setState(() {
        _surahs = surahs;
        _selectedSurah = surahs.first;
      });
    }
    await _loadSurahAyahs(1);
    _loadBibleChapter('torah');
    _loadBibleChapter('gospel');
  }

  Future<void> _loadSurahAyahs(int surahNum) async {
    await _quranAudioPlayer.stop();
    setState(() {
      _loadingQuran = true;
      _playingAyahIndex = null;
    });
    try {
      final ayahs =
          await ref.read(databaseServiceProvider).fetchSurahAyahs(surahNum);
      if (mounted) {
        setState(() {
          _ayahs = ayahs;
          _loadingQuran = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingQuran = false);
    }
  }

  Future<void> _loadBibleChapter(String testament) async {
    final db = ref.read(databaseServiceProvider);
    if (testament == 'torah') {
      setState(() => _loadingTorah = true);
      try {
        final list =
            await db.fetchBibleChapter(_selectedTorahBook, _selectedTorahChapter);
        if (mounted) {
          setState(() {
            _torahVerses = list;
            _loadingTorah = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingTorah = false);
      }
    } else {
      setState(() => _loadingGospel = true);
      try {
        final list =
            await db.fetchBibleChapter(_selectedGospelBook, _selectedGospelChapter);
        if (mounted) {
          setState(() {
            _gospelVerses = list;
            _loadingGospel = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingGospel = false);
      }
    }
  }

  Future<void> _playAyahAtIndex(int index) async {
    if (index < 0 || index >= _ayahs.length) return;
    final ayah = _ayahs[index];
    setState(() => _playingAyahIndex = index);

    final primaryUrl = ayah.audioUrl.isNotEmpty
        ? ayah.audioUrl
        : 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${ayah.globalNumber}.mp3';

    try {
      await _quranAudioPlayer.setUrl(primaryUrl);
      await _quranAudioPlayer.play();
    } catch (_) {
      try {
        final fallbackUrl =
            'https://cdn.islamic.network/quran/audio/64/ar.alafasy/${ayah.globalNumber}.mp3';
        await _quranAudioPlayer.setUrl(fallbackUrl);
        await _quranAudioPlayer.play();
      } catch (_) {
        if (mounted) setState(() => _playingAyahIndex = null);
      }
    }
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _quranAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumServiceProvider);
    final isLockedTab = (_selectedTab != 'quran') && !premium.isPremium;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 122),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "İlahi Kitaplar & Tefekkür Kütüphanesi",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            "Kur'ân-ı Kerîm • Tevrat • İncil • Karşılaştırmalı Kıssalar",
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildTraditionTab("quran", "Kur'ân-ı Kerîm", false),
                const SizedBox(width: 8),
                _buildTraditionTab("torah", "Tevrat (39 Kitap)", !premium.isPremium),
                const SizedBox(width: 8),
                _buildTraditionTab("gospel", "İncil (27 Kitap)", !premium.isPremium),
                const SizedBox(width: 8),
                _buildTraditionTab("cross_ref", "Karşılaştırma", !premium.isPremium),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Stack(
              children: [
                _buildActiveTabView(),
                if (isLockedTab) _buildBlurredPremiumLockOverlay(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabView() {
    switch (_selectedTab) {
      case 'quran':
        return _buildQuranLiveReader();
      case 'torah':
        return _buildBibleLiveReader('torah');
      case 'gospel':
        return _buildBibleLiveReader('gospel');
      case 'cross_ref':
        return _buildCrossReferenceView();
      default:
        return _buildQuranLiveReader();
    }
  }

  Widget _buildTraditionTab(String id, String title, bool showLock) {
    final selected = _selectedTab == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF64FFDA).withOpacity(0.18)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF64FFDA) : Colors.white24,
            width: 0.9,
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? const Color(0xFF64FFDA) : Colors.white,
              ),
            ),
            if (showLock) ...[
              const SizedBox(width: 6),
              const BespokeVectorIcon(
                type: BespokeIconType.lockShield,
                color: Color(0xFFFFE082),
                size: 13,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuranLiveReader() {
    return Column(
      children: [
        GlassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showSurahPickerModal(context),
                  child: Row(
                    children: [
                      const BespokeVectorIcon(
                        type: BespokeIconType.sacredScroll,
                        color: Color(0xFF64FFDA),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedSurah != null
                              ? "${_selectedSurah!.number}. ${_selectedSurah!.nameTurkish} (${_selectedSurah!.ayahCount} Ayet)"
                              : "Sure Seçin (1-114)",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64FFDA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (_playingAyahIndex != null) {
                    await _quranAudioPlayer.stop();
                    setState(() => _playingAyahIndex = null);
                  } else if (_ayahs.isNotEmpty) {
                    _playAyahAtIndex(0);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _playingAyahIndex != null
                        ? const Color(0xFFFFE082).withOpacity(0.22)
                        : const Color(0xFF64FFDA).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _playingAyahIndex != null
                          ? const Color(0xFFFFE082)
                          : const Color(0xFF64FFDA),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    children: [
                      BespokeVectorIcon(
                        type: _playingAyahIndex != null
                            ? BespokeIconType.stopSquare
                            : BespokeIconType.playTriangle,
                        color: _playingAyahIndex != null
                            ? const Color(0xFFFFE082)
                            : const Color(0xFF64FFDA),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _playingAyahIndex != null ? "Tilaveti Durdur" : "Tüm Sureyi Dinle",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _loadingQuran
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _ayahs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final a = _ayahs[index];
                    final isPlaying = _playingAyahIndex == index;

                    return GlassContainer(
                      borderRadius: 24,
                      emeraldGlow: isPlaying,
                      goldAccentBorder: isPlaying,
                      padding: const EdgeInsets.all(16),
                      onTap: () => HuzurStoryShareSheet.show(
                        context,
                        arabic: a.arabicText,
                        turkish: a.turkishText,
                        reference: "${a.surahName}, ${a.numberInSurah}",
                        category: "Kur'ân-ı Kerîm",
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${a.surahName} • Ayet ${a.numberInSurah}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isPlaying
                                      ? const Color(0xFF64FFDA)
                                      : const Color(0xFFFFE082),
                                ),
                              ),
                              Row(
                                children: [
                                  if (isPlaying)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: LiveSvgAudioVisualizer(isPlaying: true),
                                    ),
                                  GestureDetector(
                                    onTap: () async {
                                      if (isPlaying) {
                                        await _quranAudioPlayer.stop();
                                        setState(() => _playingAyahIndex = null);
                                      } else {
                                        _playAyahAtIndex(index);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isPlaying
                                            ? const Color(0xFF64FFDA).withOpacity(0.22)
                                            : Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          BespokeVectorIcon(
                                            type: isPlaying
                                                ? BespokeIconType.stopSquare
                                                : BespokeIconType.playTriangle,
                                            color: isPlaying
                                                ? const Color(0xFF64FFDA)
                                                : Colors.white,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isPlaying ? "Durdur" : "Sesli Dinle",
                                            style: const TextStyle(
                                                fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => HuzurStoryShareSheet.show(
                                      context,
                                      arabic: a.arabicText,
                                      turkish: a.turkishText,
                                      reference: "${a.surahName}, ${a.numberInSurah}",
                                      category: "Kur'ân-ı Kerîm",
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const BespokeVectorIcon(
                                        type: BespokeIconType.instagramStory,
                                        color: Color(0xFFFFE082),
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              a.arabicText,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 22,
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                                color: isPlaying
                                    ? const Color(0xFF64FFDA)
                                    : const Color(0xFFFFF8E1),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            a.turkishText,
                            style: const TextStyle(fontSize: 14, height: 1.45),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBibleLiveReader(String testament) {
    final books = DatabaseService.kAllBibleBooks
        .where((b) => b.testament == testament)
        .toList();
    final activeBook =
        testament == 'torah' ? _selectedTorahBook : _selectedGospelBook;
    final activeChapter =
        testament == 'torah' ? _selectedTorahChapter : _selectedGospelChapter;
    final verses = testament == 'torah' ? _torahVerses : _gospelVerses;
    final loading = testament == 'torah' ? _loadingTorah : _loadingGospel;
    final categoryLabel =
        testament == 'torah' ? "Tevrat • Tanah" : "İncil • Yeni Ahit";

    return Column(
      children: [
        GlassContainer(
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showBibleBookPicker(context, testament, books),
                  child: Row(
                    children: [
                      const BespokeVectorIcon(
                        type: BespokeIconType.sacredScroll,
                        color: Color(0xFFFFE082),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${activeBook.nameTurkish} • Bab $activeChapter",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFE082),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (activeChapter > 1) {
                        setState(() {
                          if (testament == 'torah') {
                            _selectedTorahChapter--;
                          } else {
                            _selectedGospelChapter--;
                          }
                        });
                        _loadBibleChapter(testament);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("Önceki Bab", style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      if (activeChapter < activeBook.totalChapters) {
                        setState(() {
                          if (testament == 'torah') {
                            _selectedTorahChapter++;
                          } else {
                            _selectedGospelChapter++;
                          }
                        });
                        _loadBibleChapter(testament);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64FFDA).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Sonraki Bab",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64FFDA),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFE082)),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: verses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final v = verses[index];
                    return GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(15),
                      onTap: () => HuzurStoryShareSheet.show(
                        context,
                        arabic: v.originalScript,
                        turkish: v.turkishText,
                        reference: "${v.bookName} ${v.chapter}:${v.verse}",
                        category: categoryLabel,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${v.bookName} ${v.chapter}:${v.verse}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFE082),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => HuzurStoryShareSheet.show(
                                  context,
                                  arabic: v.originalScript,
                                  turkish: v.turkishText,
                                  reference: "${v.bookName} ${v.chapter}:${v.verse}",
                                  category: categoryLabel,
                                ),
                                child: const BespokeVectorIcon(
                                  type: BespokeIconType.instagramStory,
                                  color: Color(0xFF64FFDA),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                          if (v.originalScript.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                v.originalScript,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFFFFF8E1),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            v.turkishText,
                            style: const TextStyle(fontSize: 14, height: 1.45),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCrossReferenceView() {
    const topics = DatabaseService.kCrossReferenceTopics;
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: topics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final cr = topics[index];
        return GlassContainer(
          borderRadius: 24,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cr.topic,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFE082),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cr.summary,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              _buildComparisonCard(
                  "KUR'ÂN-I KERÎM (${cr.quranKey})", cr.quranText, const Color(0xFF64FFDA)),
              const SizedBox(height: 8),
              _buildComparisonCard(
                  "TEVRAT (${cr.torahRef})", cr.torahText, const Color(0xFFFFE082)),
              const SizedBox(height: 8),
              _buildComparisonCard(
                  "İNCİL (${cr.gospelRef})", cr.gospelText, const Color(0xFF80D8FF)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonCard(String header, String body, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.45), width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  void _showSurahPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          builder: (context, ctrl) {
            return GlassContainer(
              borderRadius: 30,
              enableBlur: true,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "114 Sure Fihristi",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: ctrl,
                      itemCount: _surahs.length,
                      itemBuilder: (context, i) {
                        final s = _surahs[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            "${s.number}. ${s.nameTurkish}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("${s.ayahCount} Ayet"),
                          trailing: Text(
                            s.nameArabic,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFFFFE082),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => _selectedSurah = s);
                            _loadSurahAyahs(s.number);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBibleBookPicker(
    BuildContext context,
    String testament,
    List<BibleBookMeta> books,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.90,
          minChildSize: 0.5,
          builder: (context, ctrl) {
            return GlassContainer(
              borderRadius: 30,
              enableBlur: true,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testament == 'torah'
                        ? "Tevrat Kitapları (39 Kitap)"
                        : "İncil Kitapları (27 Kitap)",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: ctrl,
                      itemCount: books.length,
                      itemBuilder: (context, i) {
                        final b = books[i];
                        return ListTile(
                          title: Text(
                            "${b.bookId}. ${b.nameTurkish}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Toplam ${b.totalChapters} Bab"),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              if (testament == 'torah') {
                                _selectedTorahBook = b;
                                _selectedTorahChapter = 1;
                              } else {
                                _selectedGospelBook = b;
                                _selectedGospelChapter = 1;
                              }
                            });
                            _loadBibleChapter(testament);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBlurredPremiumLockOverlay(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          color: Colors.black.withOpacity(0.45),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: GlassContainer(
            borderRadius: 28,
            goldAccentBorder: true,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BespokeVectorIcon(
                  type: BespokeIconType.lockShield,
                  color: Color(0xFFFFE082),
                  size: 34,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Tevrat, İncil & Karşılaştırmalı İnceleme",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFE082),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "114 Sure Kur'ân-ı Kerîm ve sesli tilavet tamamen ücretsizdir. Tevrat, İncil ve Karşılaştırma modülü Huzur Özel kapsamındadır.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 18),
                GlassContainer(
                  emeraldGlow: true,
                  borderRadius: 18,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  onTap: () => LiquidGlassPaywallSheet.show(context),
                  child: const Text(
                    "Huzur Özel'i Etkinleştir",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64FFDA),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
