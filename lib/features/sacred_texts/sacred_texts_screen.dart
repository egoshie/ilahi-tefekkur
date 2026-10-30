import 'dart:async';
import 'dart:ui';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/models/v42_models.dart';
import '../../core/services/database_seeder.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/offline_sacred_repository.dart';
import '../../core/services/pricing_and_premium_service.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/glass_container.dart';
import '../../core/theme/liquid_glass_theme.dart';
import '../../core/theme/story_share_sheet.dart';
import '../paywall/liquid_glass_paywall.dart';

class SacredTextsScreen extends ConsumerStatefulWidget {
  const SacredTextsScreen({super.key});

  @override
  ConsumerState< SacredTextsScreen > createState() => _SacredTextsScreenState();
}

class _SacredTextsScreenState extends ConsumerState< SacredTextsScreen > {
  String _selectedTab = 'quran';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List< SurahMeta > _surahs = [];
  SurahMeta? _selectedSurah;
  List< LiveAyahItem > _ayahs = [];
  bool _loadingQuran = false;
  String? _audioErrorBanner;

  late BibleBookMeta _selectedTorahBook;
  int _selectedTorahChapter = 1;
  List< BibleVerseItem > _torahVerses = [];
  bool _loadingTorah = false;

  late BibleBookMeta _selectedGospelBook;
  int _selectedGospelChapter = 1;
  List< BibleVerseItem > _gospelVerses = [];
  bool _loadingGospel = false;

  final AudioPlayer _quranAudioPlayer = AudioPlayer();
  StreamSubscription< PlayerState >? _playerSub;
  int? _playingAyahIndex;
  bool _isPaused = false;

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

  Future< void > _setupAudioListener() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _playerSub = _quranAudioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_playingAyahIndex != null &&
            _playingAyahIndex! + 1 < _ayahs.length) {
          _playAyahAtIndex(_playingAyahIndex! + 1);
        } else {
          if (mounted) {
            setState(() {
              _playingAyahIndex = null;
              _isPaused = false;
            });
          }
        }
      }
    });
  }

  Future< void > _loadInitialCatalogs() async {
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

  Future< void > _loadSurahAyahs(int surahNum) async {
    await _quranAudioPlayer.stop();
    setState(() {
      _loadingQuran = true;
      _playingAyahIndex = null;
      _isPaused = false;
      _audioErrorBanner = null;
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
      final meta = _surahs.where((s) => s.number == surahNum).toList();
      if (meta.isNotEmpty) {
        await ref.read(userProgressProvider.notifier).saveLastRead(
              LastReadPosition(
                tradition: 'quran',
                bookOrSurahId: surahNum,
                title: meta.first.nameTurkish,
                chapterOrAyah: 1,
              ),
            );
      }
    } catch (_) {
      if (mounted) setState(() => _loadingQuran = false);
    }
  }

  Future< void > _loadBibleChapter(String testament) async {
    final db = ref.read(databaseServiceProvider);
    if (testament == 'torah') {
      setState(() => _loadingTorah = true);
      try {
        final list = await db.fetchBibleChapter(
            _selectedTorahBook, _selectedTorahChapter);
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
        final list = await db.fetchBibleChapter(
            _selectedGospelBook, _selectedGospelChapter);
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

  Future< void > _playAyahAtIndex(int index) async {
    if (index < 0 || index >= _ayahs.length) return;
    final ayah = _ayahs[index];
    setState(() {
      _playingAyahIndex = index;
      _isPaused = false;
      _audioErrorBanner = null;
    });

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
        if (mounted) {
          setState(() {
            _playingAyahIndex = null;
            _isPaused = false;
            _audioErrorBanner =
                "Ses akışı için internet bağlantısı gereklidir.";
          });
        }
      }
    }
  }

  Future< void > _togglePauseOrResume() async {
    if (_playingAyahIndex == null) return;
    if (_quranAudioPlayer.playing) {
      await _quranAudioPlayer.pause();
      if (mounted) setState(() => _isPaused = true);
    } else {
      await _quranAudioPlayer.play();
      if (mounted) setState(() => _isPaused = false);
    }
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    _quranAudioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List< SurahMeta > get _matchingSurahs {
    if (_searchQuery.trim().isEmpty) return const [];
    return _surahs.where((s) {
      final combined = '${s.number} ${s.nameTurkish}';
      return TurkishSearchNormalizer.matches(combined, _searchQuery);
    }).toList();
  }

  List< LiveAyahItem > get _filteredAyahs {
    if (_searchQuery.trim().isEmpty) return _ayahs;
    return _ayahs.where((a) {
      final combined =
          '${a.surahName} ${a.numberInSurah} ${a.turkishText} ${a.arabicText}';
      return TurkishSearchNormalizer.matches(combined, _searchQuery);
    }).toList();
  }

  List< BibleVerseItem > _filterBibleVerses(List< BibleVerseItem > source) {
    if (_searchQuery.trim().isEmpty) return source;
    return source.where((v) {
      final combined = '${v.bookName} ${v.chapter}:${v.verse} ${v.turkishText}';
      return TurkishSearchNormalizer.matches(combined, _searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumServiceProvider);
    final isLockedTab =
        (_selectedTab == 'torah' ||
            _selectedTab == 'gospel' ||
            _selectedTab == 'cross_ref') &&
        !premium.isPremium;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 135),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "İlahi Kitaplar & Tefekkür Kütüphanesi",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            "Kur'ân-ı Kerîm • Tevrat • İncil • Kaydedilen Ayetler",
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 10),

          // Canlı Türkçe Karakter Duyarsız Arama Çubuğu
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                const BespokeVectorIcon(
                  type: BespokeIconType.searchLens,
                  color: Color(0xFF64FFDA),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: "Sure adı, numarası veya ayet kelimesi ara...",
                      hintStyle: TextStyle(color: Colors.white54, fontSize: 12.5),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Text(
                      "Temizle",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFE082),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildTraditionTab("quran", "Kur'ân-ı Kerîm", false),
                const SizedBox(width: 8),
                _buildTraditionTab("saved", "Favori & Yer İmi", false),
                const SizedBox(width: 8),
                _buildTraditionTab("torah", "Tevrat (39 Kitap)", !premium.isPremium),
                const SizedBox(width: 8),
                _buildTraditionTab("gospel", "İncil (27 Kitap)", !premium.isPremium),
                const SizedBox(width: 8),
                _buildTraditionTab("cross_ref", "Karşılaştırma", !premium.isPremium),
              ],
            ),
          ),
          const SizedBox(height: 10),

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
      case 'saved':
        return _buildSavedVersesView();
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
    final progress = ref.watch(userProgressProvider);
    final progressNotifier = ref.read(userProgressProvider.notifier);
    final matchedSurahs = _matchingSurahs;
    final ayahsToDisplay = _filteredAyahs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arama sorgusu bir sure adıyla eşleşiyorsa (örn: duha, fatiha, yasin, insirah) hızlı geçiş çipleri
        if (matchedSurahs.isNotEmpty) ...[
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: matchedSurahs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final s = matchedSurahs[idx];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSurah = s;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    _loadSurahAyahs(s.number);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE082).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082), width: 0.9),
                    ),
                    child: Center(
                      child: Text(
                        "Sureye Git: ${s.number}. ${s.nameTurkish}",
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFE082),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

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
              if (_playingAyahIndex != null) ...[
                GestureDetector(
                  onTap: _togglePauseOrResume,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: BespokeVectorIcon(
                      type: _isPaused
                          ? BespokeIconType.playTriangle
                          : BespokeIconType.pauseBars,
                      color: const Color(0xFF64FFDA),
                      size: 13,
                    ),
                  ),
                ),
              ],
              GestureDetector(
                onTap: () async {
                  if (_playingAyahIndex != null) {
                    await _quranAudioPlayer.stop();
                    setState(() {
                      _playingAyahIndex = null;
                      _isPaused = false;
                    });
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
                        _playingAyahIndex != null ? "Durdur" : "Sureyi Dinle",
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_audioErrorBanner != null) ...[
          const SizedBox(height: 6),
          Text(
            _audioErrorBanner!,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFFFFE082)),
          ),
        ],
        const SizedBox(height: 10),

        Expanded(
          child: _loadingQuran
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: ayahsToDisplay.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final a = ayahsToDisplay[index];
                    final origIdx = _ayahs.indexOf(a);
                    final isPlaying = _playingAyahIndex == origIdx;
                    final isFav = progress.isFavorite(a.uniqueKey);
                    final isBm = progress.isBookmarked(a.uniqueKey);

                    return GlassContainer(
                      borderRadius: 24,
                      emeraldGlow: isPlaying,
                      goldAccentBorder: isPlaying || isBm,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${a.surahName} • Ayet ${a.numberInSurah}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isPlaying
                                        ? const Color(0xFF64FFDA)
                                        : const Color(0xFFFFE082),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  if (isPlaying)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: LiveSvgAudioVisualizer(
                                        isPlaying: !_isPaused,
                                      ),
                                    ),
                                  // Sesli Dinle
                                  _buildActionButton(
                                    icon: isPlaying && !_isPaused
                                        ? BespokeIconType.pauseBars
                                        : BespokeIconType.playTriangle,
                                    color: isPlaying
                                        ? const Color(0xFF64FFDA)
                                        : Colors.white70,
                                    onTap: () {
                                      if (isPlaying) {
                                        _togglePauseOrResume();
                                      } else {
                                        _playAyahAtIndex(origIdx);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  // Favori
                                  _buildActionButton(
                                    icon: BespokeIconType.heartFavorite,
                                    color: isFav
                                        ? const Color(0xFFFF8A80)
                                        : Colors.white54,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      progressNotifier.toggleFavorite(
                                        SavedVerseRef(
                                          key: a.uniqueKey,
                                          tradition: 'quran',
                                          reference:
                                              "${a.surahName}, ${a.numberInSurah}",
                                          arabic: a.arabicText,
                                          turkish: a.turkishText,
                                          savedAtEpochMs: DateTime.now()
                                              .millisecondsSinceEpoch,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  // Yer İmi & Kaldığım Yer
                                  _buildActionButton(
                                    icon: BespokeIconType.bookmarkStar,
                                    color: isBm
                                        ? const Color(0xFFFFE082)
                                        : Colors.white54,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      progressNotifier.toggleBookmark(
                                        SavedVerseRef(
                                          key: a.uniqueKey,
                                          tradition: 'quran',
                                          reference:
                                              "${a.surahName}, ${a.numberInSurah}",
                                          arabic: a.arabicText,
                                          turkish: a.turkishText,
                                          savedAtEpochMs: DateTime.now()
                                              .millisecondsSinceEpoch,
                                        ),
                                      );
                                      progressNotifier.saveLastRead(
                                        LastReadPosition(
                                          tradition: 'quran',
                                          bookOrSurahId: a.surahNumber,
                                          title: a.surahName,
                                          chapterOrAyah: a.numberInSurah,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  // Widget Yap
                                  _buildActionButton(
                                    icon: BespokeIconType.widgetSpark,
                                    color: const Color(0xFF64FFDA),
                                    onTap: () async {
                                      HapticFeedback.mediumImpact();
                                      await NotificationAndWidgetService.instance
                                          .pinCustomVerseToWidget(
                                        arabic: a.arabicText,
                                        turkish: a.turkishText,
                                        reference:
                                            "${a.surahName}, ${a.numberInSurah}",
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  // Paylaş
                                  _buildActionButton(
                                    icon: BespokeIconType.instagramStory,
                                    color: const Color(0xFFFFE082),
                                    onTap: () => HuzurStoryShareSheet.show(
                                      context,
                                      arabic: a.arabicText,
                                      turkish: a.turkishText,
                                      reference:
                                          "${a.surahName}, ${a.numberInSurah}",
                                      category: "Kur'ân-ı Kerîm",
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

  Widget _buildSavedVersesView() {
    final progress = ref.watch(userProgressProvider);
    final combined = < SavedVerseRef >[
      ...progress.bookmarks,
      ...progress.favorites.where(
        (f) => !progress.bookmarks.any((b) => b.key == f.key),
      ),
    ];

    if (combined.isEmpty) {
      return Center(
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: const Text(
            "Henüz favori veya yer imi eklemediniz.\nAyet kartlarındaki kalp veya yer imi ikonuna dokunarak kaydedebilirsiniz.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: combined.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final item = combined[idx];
        return GlassContainer(
          borderRadius: 22,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(16),
          onTap: () => HuzurStoryShareSheet.show(
            context,
            arabic: item.arabic,
            turkish: item.turkish,
            reference: item.reference,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.reference,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFE082),
                    ),
                  ),
                  const BespokeVectorIcon(
                    type: BespokeIconType.instagramStory,
                    color: Color(0xFF64FFDA),
                    size: 16,
                  ),
                ],
              ),
              if (item.arabic.isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    item.arabic,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFFFFF8E1),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                item.turkish,
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BespokeIconType icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: BespokeVectorIcon(
          type: icon,
          color: color,
          size: 14,
        ),
      ),
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
    final rawVerses = testament == 'torah' ? _torahVerses : _gospelVerses;
    final verses = _filterBibleVerses(rawVerses);
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Önceki Bab",
                        style: TextStyle(fontSize: 11),
                      ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
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
                              Row(
                                children: [
                                  _buildActionButton(
                                    icon: BespokeIconType.widgetSpark,
                                    color: const Color(0xFF64FFDA),
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      NotificationAndWidgetService.instance
                                          .pinCustomVerseToWidget(
                                        arabic: v.originalScript,
                                        turkish: v.turkishText,
                                        reference:
                                            "${v.bookName} ${v.chapter}:${v.verse}",
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  _buildActionButton(
                                    icon: BespokeIconType.instagramStory,
                                    color: const Color(0xFFFFE082),
                                    onTap: () => HuzurStoryShareSheet.show(
                                      context,
                                      arabic: v.originalScript,
                                      turkish: v.turkishText,
                                      reference:
                                          "${v.bookName} ${v.chapter}:${v.verse}",
                                      category: categoryLabel,
                                    ),
                                  ),
                                ],
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
    final allTopics = DatabaseService.kCrossReferenceTopics;
    final topics = _searchQuery.trim().isEmpty
        ? allTopics
        : allTopics
            .where((t) => TurkishSearchNormalizer.matches(
                '${t.topic} ${t.summary} ${t.quranText} ${t.torahText} ${t.gospelText}',
                _searchQuery))
            .toList();

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
              _buildComparisonCard("KUR'ÂN-I KERÎM (${cr.quranKey})",
                  cr.quranText, const Color(0xFF64FFDA)),
              const SizedBox(height: 8),
              _buildComparisonCard("TEVRAT (${cr.torahRef})", cr.torahText,
                  const Color(0xFFFFE082)),
              const SizedBox(height: 8),
              _buildComparisonCard("İNCİL (${cr.gospelRef})", cr.gospelText,
                  const Color(0xFF80D8FF)),
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
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: accent),
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
        String modalSearch = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = modalSearch.trim().isEmpty
                ? _surahs
                : _surahs
                    .where((s) => TurkishSearchNormalizer.matches(
                        '${s.number} ${s.nameTurkish}', modalSearch))
                    .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.80,
              maxChildSize: 0.92,
              minChildSize: 0.50,
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
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      GlassContainer(
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: TextField(
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: "Sure adı veya numarası yazın (örn: duha, yasin)...",
                            hintStyle:
                                TextStyle(color: Colors.white54, fontSize: 12),
                            border: InputBorder.none,
                          ),
                          onChanged: (v) => setModalState(() => modalSearch = v),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: ctrl,
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final s = filtered[i];
                            return ListTile(
                              dense: true,
                              title: Text(
                                "${s.number}. ${s.nameTurkish}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
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
      },
    );
  }

  void _showBibleBookPicker(
    BuildContext context,
    String testament,
    List< BibleBookMeta > books,
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
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
                  style: TextStyle(
                      fontSize: 13, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 18),
                GlassContainer(
                  emeraldGlow: true,
                  borderRadius: 18,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 20),
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
