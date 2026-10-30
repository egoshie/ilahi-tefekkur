import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/app_models.dart';
import '../../core/services/database_seeder.dart';
import '../../core/services/notification_service.dart';
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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _focusVerseNumber;
  List<Map<String, dynamic>> _bookmarks = [];
  Map<String, dynamic>? _lastPlace;

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
    _loadSavedReadingState();
    _loadInitialCatalogs();
  }

  String _normalizeSearch(String value) {
    const replacements = {'İ':'i','I':'i','ı':'i','Ş':'s','ş':'s','Ğ':'g','ğ':'g','Ü':'u','ü':'u','Ö':'o','ö':'o','Ç':'c','ç':'c','Â':'a','â':'a','Î':'i','î':'i','Û':'u','û':'u','Ê':'e','ê':'e'};
    var result = value;
    replacements.forEach((from, to) { result = result.replaceAll(from, to); });
    return result.toLowerCase();
  }

  bool _matchesSearch(String value) => _searchQuery.trim().isEmpty || _normalizeSearch(value).contains(_normalizeSearch(_searchQuery.trim()));

  Future<void> _loadSavedReadingState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('huzur_v42_bookmarks') ?? const <String>[];
    final parsed = <Map<String, dynamic>>[];
    for (final value in saved) {
      try { parsed.add(Map<String, dynamic>.from(jsonDecode(value) as Map)); } catch (_) {}
    }
    final rawLast = prefs.getString('huzur_v42_last_place');
    if (!mounted) return;
    setState(() {
      _bookmarks = parsed;
      if (rawLast != null) {
        try { _lastPlace = Map<String, dynamic>.from(jsonDecode(rawLast) as Map); } catch (_) {}
      }
    });
  }

  Future<void> _saveLastPlace(Map<String, dynamic> place) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('huzur_v42_last_place', jsonEncode(place));
    if (mounted) setState(() => _lastPlace = place);
  }

  bool _hasBookmark(String id) => _bookmarks.any((item) => item['id'] == id);

  Future<void> _toggleBookmark(Map<String, dynamic> item) async {
    final id = item['id'].toString();
    final next = List<Map<String, dynamic>>.from(_bookmarks);
    if (next.any((value) => value['id'] == id)) {
      next.removeWhere((value) => value['id'] == id);
    } else {
      next.insert(0, item);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('huzur_v42_bookmarks', next.map((value) => jsonEncode(value)).toList());
    if (mounted) setState(() => _bookmarks = next);
  }

  Widget _highlightSearchText(String value, TextStyle style) {
    final query = _searchQuery.trim();
    if (query.isEmpty) return Text(value, style: style);
    final folded = _normalizeSearch(value);
    final foldedQuery = _normalizeSearch(query);
    final start = folded.indexOf(foldedQuery);
    if (start < 0 || start + foldedQuery.length > value.length) return Text(value, style: style);
    final end = start + foldedQuery.length;
    return Text.rich(TextSpan(children: [
      TextSpan(text: value.substring(0, start), style: style),
      TextSpan(text: value.substring(start, end), style: style.copyWith(backgroundColor: const Color(0xFFFFD54F).withOpacity(0.28), color: const Color(0xFFFFE082))),
      TextSpan(text: value.substring(end), style: style),
    ]));
  }

  Future<void> _openSavedPlace(Map<String, dynamic> place) async {
    final tab = (place['tab'] ?? 'quran').toString();
    if (tab == 'quran') {
      final number = int.tryParse((place['surah'] ?? '1').toString()) ?? 1;
      final found = _surahs.where((s) => s.number == number).toList();
      if (found.isEmpty) return;
      final verse = int.tryParse((place['verse'] ?? '').toString());
      setState(() { _selectedTab = 'quran'; _selectedSurah = found.first; _searchQuery = ''; _searchController.clear(); _focusVerseNumber = verse; });
      await _loadSurahAyahs(number);
    } else {
      final bookId = int.tryParse((place['bookId'] ?? '').toString());
      final chapter = int.tryParse((place['chapter'] ?? '1').toString()) ?? 1;
      final books = DatabaseService.kAllBibleBooks.where((b) => b.testament == tab && (bookId == null || b.bookId == bookId)).toList();
      if (books.isEmpty) return;
      final verse = int.tryParse((place['verse'] ?? '').toString());
      setState(() {
        _selectedTab = tab; _searchQuery = ''; _searchController.clear(); _focusVerseNumber = verse;
        if (tab == 'torah') { _selectedTorahBook = books.first; _selectedTorahChapter = chapter; }
        else { _selectedGospelBook = books.first; _selectedGospelChapter = chapter; }
      });
      await _loadBibleChapter(tab);
    }
  }

  void _showBookmarksAndLastPlace() {
    showModalBottomSheet<void>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.72, maxChildSize: 0.92, minChildSize: 0.5,
        builder: (context, controller) => GlassContainer(
          borderRadius: 28, enableBlur: true, padding: const EdgeInsets.all(18),
          child: ListView(controller: controller, children: [
            const Text('Kaldığım Yer & Favoriler', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFFFFE082))),
            const SizedBox(height: 10),
            if (_lastPlace != null) ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF64FFDA)),
              title: const Text('Kaldığın yere dön'),
              subtitle: Text((_lastPlace!['label'] ?? 'Son okuma konumu').toString()),
              onTap: () { Navigator.pop(sheetContext); _openSavedPlace(_lastPlace!); },
            ) else const Text('Henüz kayıtlı bir okuma konumu yok.', style: TextStyle(color: Colors.white60, fontSize: 12)),
            const Divider(color: Colors.white24),
            if (_bookmarks.isEmpty) const Text('Henüz favori ayet eklemedin.', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ..._bookmarks.map((item) => ListTile(
              leading: const Icon(Icons.bookmark, color: Color(0xFFFFE082)),
              title: Text((item['label'] ?? 'Favori ayet').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text((item['text'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () { Navigator.pop(sheetContext); _openSavedPlace(item); },
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white60), onPressed: () async {
                final id = (item['id'] ?? '').toString();
                final next = List<Map<String, dynamic>>.from(_bookmarks)..removeWhere((value) => value['id'] == id);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setStringList('huzur_v42_bookmarks', next.map((value) => jsonEncode(value)).toList());
                if (mounted) setState(() => _bookmarks = next);
              }),
            )),
          ]),
        ),
      ),
    );
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
        await _saveLastPlace({
          'tab': 'quran',
          'surah': surahNum.toString(),
          if (_focusVerseNumber != null) 'verse': _focusVerseNumber.toString(),
          'label': (_selectedSurah?.nameTurkish ?? 'Sure') + ' • ' + surahNum.toString(),
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
          await _saveLastPlace({'tab':'torah','bookId':_selectedTorahBook.bookId,'chapter':_selectedTorahChapter, if (_focusVerseNumber != null) 'verse': _focusVerseNumber.toString(), 'label':_selectedTorahBook.nameTurkish + ' • Bab ' + _selectedTorahChapter.toString()});
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
          await _saveLastPlace({'tab':'gospel','bookId':_selectedGospelBook.bookId,'chapter':_selectedGospelChapter, if (_focusVerseNumber != null) 'verse': _focusVerseNumber.toString(), 'label':_selectedGospelBook.nameTurkish + ' • Bab ' + _selectedGospelChapter.toString()});
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
    _searchController.dispose();
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
          GlassContainer(
            borderRadius: 16, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: Row(children: [
              const Icon(Icons.search, color: Color(0xFF64FFDA), size: 20),
              const SizedBox(width: 8),
              Expanded(child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() { _searchQuery = value; _focusVerseNumber = null; }),
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none, hintText: 'Sure adı, numarası veya ayet kelimesi ara... Örn: Yasin, Bakara, 36, Sabır',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              )),
              if (_searchQuery.isNotEmpty) IconButton(
                visualDensity: VisualDensity.compact, icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                onPressed: () { _searchController.clear(); setState(() { _searchQuery = ''; _focusVerseNumber = null; }); },
              ),
            ]),
          ),
          const SizedBox(height: 7),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(
            onPressed: _showBookmarksAndLastPlace,
            icon: const Icon(Icons.bookmarks_outlined, size: 16, color: Color(0xFFFFE082)),
            label: Text('Kaldığım Yer & Favoriler (' + _bookmarks.length.toString() + ')', style: const TextStyle(fontSize: 11, color: Color(0xFFFFE082))),
          )),
          const SizedBox(height: 4),

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
      onTap: () => setState(() { _selectedTab = id; _focusVerseNumber = null; }),
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
    final matchingSurahs = _searchQuery.trim().isEmpty ? const [] : _surahs.where((s) => _matchesSearch(s.nameTurkish + ' ' + s.number.toString() + ' ' + s.nameArabic)).take(8).toList();
    final visibleAyahs = _ayahs.where((a) {
      if (_focusVerseNumber != null) return a.numberInSurah == _focusVerseNumber;
      return _matchesSearch(a.surahName + ' ' + a.numberInSurah.toString() + ' ' + (_selectedSurah?.number.toString() ?? '') + ' ' + a.turkishText);
    }).toList();
    return Column(
      children: [
        if (matchingSurahs.isNotEmpty) SizedBox(height: 48, child: ListView.separated(
          scrollDirection: Axis.horizontal, itemCount: matchingSurahs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (context, index) { final s = matchingSurahs[index]; return ActionChip(
            backgroundColor: const Color(0xFF64FFDA).withOpacity(0.12),
            label: Text(s.number.toString() + '. ' + s.nameTurkish, style: const TextStyle(fontSize: 11, color: Color(0xFF64FFDA))),
            onPressed: () { setState(() => _selectedSurah = s); _loadSurahAyahs(s.number); },
          ); },
        )),
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
                  itemCount: visibleAyahs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final a = visibleAyahs[index];
                    final sourceIndex = _ayahs.indexOf(a);
                    final isPlaying = _playingAyahIndex == sourceIndex;

                    return GlassContainer(
                      borderRadius: 24,
                      emeraldGlow: isPlaying,
                      goldAccentBorder: isPlaying,
                      padding: const EdgeInsets.all(16),
                      onTap: () { _saveLastPlace({'tab':'quran','surah':_selectedSurah?.number.toString() ?? '1','verse':a.numberInSurah.toString(),'label':a.surahName + ' • Ayet ' + a.numberInSurah.toString()}); HuzurStoryShareSheet.show(
                        context,
                        arabic: a.arabicText,
                        turkish: a.turkishText,
                        reference: "${a.surahName}, ${a.numberInSurah}",
                        category: "Kur'ân-ı Kerîm",
                      ); },
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
                                        _playAyahAtIndex(sourceIndex);
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
                                  const SizedBox(width: 4),
                                  IconButton(
                                    visualDensity: VisualDensity.compact, padding: EdgeInsets.zero,
                                    icon: Icon(_hasBookmark('quran|' + (_selectedSurah?.number.toString() ?? '0') + '|' + a.numberInSurah.toString()) ? Icons.bookmark : Icons.bookmark_border, color: const Color(0xFFFFE082), size: 20),
                                    onPressed: () => _toggleBookmark({
                                      'id':'quran|' + (_selectedSurah?.number.toString() ?? '0') + '|' + a.numberInSurah.toString(),
                                      'tab':'quran','surah':_selectedSurah?.number.toString() ?? '1','verse':a.numberInSurah.toString(),
                                      'label':a.surahName + ' • Ayet ' + a.numberInSurah.toString(),
                                      'text':a.turkishText,'arabic':a.arabicText,
                                    }),
                                  ),
                                  IconButton(
                                    tooltip: 'Widget yap',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.widgets_outlined, color: Color(0xFF64FFDA), size: 19),
                                    onPressed: () async {
                                      await NotificationAndWidgetService.instance.updateWidgetVerse(
                                        arabic: a.arabicText,
                                        turkish: a.turkishText,
                                        reference: a.surahName + ', ' + a.numberInSurah.toString(),
                                      );
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ayet Huzur widget’ına aktarıldı.')));
                                    },
                                  ),
                                  const SizedBox(width: 3),
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
                          _highlightSearchText(a.turkishText, const TextStyle(fontSize: 14, height: 1.45)),
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
    final allVerses = testament == 'torah' ? _torahVerses : _gospelVerses;
    final verses = allVerses.where((v) {
      if (_focusVerseNumber != null) return v.verse == _focusVerseNumber;
      return _matchesSearch(v.bookName + ' ' + v.chapter.toString() + ':' + v.verse.toString() + ' ' + v.turkishText);
    }).toList();
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
                          _focusVerseNumber = null;
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
                          _focusVerseNumber = null;
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
                      onTap: () {
                        _saveLastPlace({'tab':testament,'bookId':activeBook.bookId.toString(),'chapter':activeChapter.toString(),'verse':v.verse.toString(),'label':v.bookName + ' ' + v.chapter.toString() + ':' + v.verse.toString()});
                        HuzurStoryShareSheet.show(
                        context,
                        arabic: v.originalScript,
                        turkish: v.turkishText,
                        reference: "${v.bookName} ${v.chapter}:${v.verse}",
                        category: categoryLabel,
                      ); },
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
                              Row(children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact, padding: EdgeInsets.zero,
                                  icon: Icon(_hasBookmark(testament + '|' + activeBook.bookId.toString() + '|' + activeChapter.toString() + '|' + v.verse.toString()) ? Icons.bookmark : Icons.bookmark_border, color: const Color(0xFFFFE082), size: 19),
                                  onPressed: () => _toggleBookmark({
                                    'id':testament + '|' + activeBook.bookId.toString() + '|' + activeChapter.toString() + '|' + v.verse.toString(),
                                    'tab':testament,'bookId':activeBook.bookId.toString(),'chapter':activeChapter.toString(),
                                    'label':v.bookName + ' ' + v.chapter.toString() + ':' + v.verse.toString(),
                                    'text':v.turkishText,'arabic':v.originalScript,
                                  }),
                                ),
                                IconButton(
                                  tooltip: 'Widget yap',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.widgets_outlined, color: Color(0xFF64FFDA), size: 18),
                                  onPressed: () async {
                                    await NotificationAndWidgetService.instance.updateWidgetVerse(
                                      arabic: v.originalScript,
                                      turkish: v.turkishText,
                                      reference: v.bookName + ' ' + v.chapter.toString() + ':' + v.verse.toString(),
                                    );
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Metin Huzur widget’ına aktarıldı.')));
                                  },
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
                              ]),
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
                          _highlightSearchText(v.turkishText, const TextStyle(fontSize: 14, height: 1.45)),
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
                      itemCount: _surahs.where((s) => _matchesSearch(s.nameTurkish + ' ' + s.nameArabic + ' ' + s.number.toString())).length,
                      itemBuilder: (context, i) {
                        final filtered = _surahs.where((s) => _matchesSearch(s.nameTurkish + ' ' + s.nameArabic + ' ' + s.number.toString())).toList();
                        final s = filtered[i];
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
                            setState(() { _selectedSurah = s; _focusVerseNumber = null; });
                            _saveLastPlace({'tab':'quran','surah':s.number.toString(),'label':s.nameTurkish + ' • Sure'});
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
                              _focusVerseNumber = null;
                              if (testament == 'torah') {
                                _selectedTorahBook = b;
                                _selectedTorahChapter = 1;
                              } else {
                                _selectedGospelBook = b;
                                _selectedGospelChapter = 1;
                              }
                            });
                            _saveLastPlace({'tab':testament,'bookId':b.bookId.toString(),'chapter':'1','label':b.nameTurkish + ' • Bab 1'});
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