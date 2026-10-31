import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/v42_models.dart';
import '../../core/services/database_seeder.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/offline_sacred_repository.dart';
import '../../core/services/pricing_and_premium_service.dart';
import '../../core/services/quran_background_audio_service.dart';
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

  late BibleBookMeta _selectedTorahBook;
  int _selectedTorahChapter = 1;
  List< BibleVerseItem > _torahVerses = [];
  bool _loadingTorah = false;

  late BibleBookMeta _selectedGospelBook;
  int _selectedGospelChapter = 1;
  List< BibleVerseItem > _gospelVerses = [];
  bool _loadingGospel = false;

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

    _loadInitialCatalogs();
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
    setState(() => _loadingQuran = true);
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

  @override
  void dispose() {
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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
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
          const SizedBox(height: 10),

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
                    textInputAction: TextInputAction.search,
                        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                        decoration: const InputDecoration(
                      hintText: "Sure adı, numarası veya ayet kelimesi ara...",
                      hintStyle: TextStyle(color: Colors.white54, fontSize: 12.5),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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

          // Kesilmeyen Yatay Sekme Barı
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 16),
              children: [
                _buildTraditionTab("quran", "Kur'ân-ı Kerîm", false),
                const SizedBox(width: 8),
                _buildTraditionTab("torah", "Tevrat (39 Kitap)", !premium.isPremium),
                const SizedBox(width: 8),
                _buildTraditionTab("gospel", "İncil (27 Kitap)", !premium.isPremium),
                const SizedBox(width: 8),
                _buildTraditionTab("cross_ref", "Karşılaştırma", !premium.isPremium),
                const SizedBox(width: 8),
                _buildTraditionTab("saved", "Favorilerim", false),
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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF64FFDA).withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF64FFDA) : Colors.white24,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
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
    final audioState = ref.watch(quranAudioProvider);
    final audioNotifier = ref.read(quranAudioProvider.notifier);

    final matchedSurahs = _matchingSurahs;
    final ayahsToDisplay = _filteredAyahs;
    final isCurrentSurahPlaying = audioState.activeAyah != null &&
        _selectedSurah != null &&
        audioState.activeAyah!.surahNumber == _selectedSurah!.number;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (matchedSurahs.isNotEmpty) ...[
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE082).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFFFE082), width: 0.9),
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
              GestureDetector(
                onTap: () async {
                  if (isCurrentSurahPlaying) {
                    await audioNotifier.togglePlayPause();
                  } else if (_ayahs.isNotEmpty) {
                    await audioNotifier.startSurahPlaylist(_ayahs, startIndex: 0);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isCurrentSurahPlaying && audioState.isPlaying
                        ? const Color(0xFFFFE082).withValues(alpha: 0.24)
                        : const Color(0xFF64FFDA).withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrentSurahPlaying && audioState.isPlaying
                          ? const Color(0xFFFFE082)
                          : const Color(0xFF64FFDA),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    children: [
                      BespokeVectorIcon(
                        type: isCurrentSurahPlaying && audioState.isPlaying
                            ? BespokeIconType.pauseBars
                            : BespokeIconType.playTriangle,
                        color: isCurrentSurahPlaying && audioState.isPlaying
                            ? const Color(0xFFFFE082)
                            : const Color(0xFF64FFDA),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCurrentSurahPlaying && audioState.isPlaying
                            ? "Duraklat"
                            : "Sureyi Dinle",
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
        if (audioState.errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            audioState.errorMessage!,
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
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: ayahsToDisplay.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final a = ayahsToDisplay[index];
                    final origIdx = _ayahs.indexOf(a);
                    final isPlaying = audioState.activeAyah?.uniqueKey ==
                        a.uniqueKey;
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
                                        isPlaying: audioState.isPlaying,
                                      ),
                                    ),
                                  _buildActionButton(
                                    icon: isPlaying && audioState.isPlaying
                                        ? BespokeIconType.pauseBars
                                        : BespokeIconType.playTriangle,
                                    color: isPlaying
                                        ? const Color(0xFF64FFDA)
                                        : Colors.white70,
                                    onTap: () {
                                      if (isPlaying) {
                                        audioNotifier.togglePlayPause();
                                      } else {
                                        audioNotifier.startSurahPlaylist(
                                          _ayahs,
                                          startIndex: origIdx >= 0 ? origIdx : 0,
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 6),
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
                                          turkishText: a.turkishText,
                                          savedAtEpochMs: DateTime.now()
                                              .millisecondsSinceEpoch,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
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
                                          turkishText: a.turkishText,
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
                                  _buildActionButton(
                                    icon: BespokeIconType.widgetSpark,
                                    color: const Color(0xFF64FFDA),
                                    onTap: () async {
                                      HapticFeedback.mediumImpact();
                                      await NotificationAndWidgetService.instance
                                          .pinCustomVerseToWidget(
                                        arabic: a.arabicText,
                                        turkishText: a.turkishText,
                                        reference:
                                            "${a.surahName}, ${a.numberInSurah}",
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  _buildActionButton(
                                    icon: BespokeIconType.instagramStory,
                                    color: const Color(0xFFFFE082),
                                    onTap: () => StoryShareSheet.show(
                                      context,
                                      arabic: a.arabicText,
                                      turkishText: a.turkishText,
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: combined.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final item = combined[idx];
        return GlassContainer(
          borderRadius: 22,
          goldAccentBorder: true,
          padding: const EdgeInsets.all(16),
          onTap: () => StoryShareSheet.show(
            context,
            arabic: item.arabic,
            turkishText: item.turkish,
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
          color: Colors.white.withValues(alpha: 0.08),
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
                        color: Colors.white.withValues(alpha: 0.08),
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
                        color: const Color(0xFF64FFDA).withValues(alpha: 0.18),
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
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: verses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final v = verses[index];
                    return GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(15),
                      onTap: () => StoryShareSheet.show(
                        context,
                        arabic: v.originalScript,
                        turkishText: v.turkishText,
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
                                        turkishText: v.turkishText,
                                        reference:
                                            "${v.bookName} ${v.chapter}:${v.verse}",
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  _buildActionButton(
                                    icon: BespokeIconType.instagramStory,
                                    color: const Color(0xFFFFE082),
                                    onTap: () => StoryShareSheet.show(
                                      context,
                                      arabic: v.originalScript,
                                      turkishText: v.turkishText,
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
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
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 0.9),
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
                          textInputAction: TextInputAction.search,
                        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                        decoration: const InputDecoration(
                            hintText:
                                "Sure adı veya numarası yazın (örn: duha, yasin)...",
                            hintStyle:
                                TextStyle(color: Colors.white54, fontSize: 12),
                            border: InputBorder.none,
                          ),
                          onChanged: (v) =>
                              setModalState(() => modalSearch = v),
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
          color: Colors.black.withValues(alpha: 0.45),
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
