import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/app_models.dart';
import 'offline_sacred_repository.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ilahi_tefekkur_v3_master.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_surahs (
            surah_number INTEGER PRIMARY KEY,
            payload TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_bible_chapters (
            cache_key TEXT PRIMARY KEY,
            payload TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE verse_notes (
            verse_key TEXT PRIMARY KEY,
            note TEXT,
            is_bookmarked INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE tasbih_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            arabic TEXT,
            count INTEGER,
            target INTEGER,
            is_custom INTEGER DEFAULT 0
          )
        ''');

        await db.insert('tasbih_records', {
          'title': 'Sübhanallah',
          'arabic': 'سُبْحَانَ ٱللَّهِ',
          'count': 0,
          'target': 33,
          'is_custom': 0,
        });
        await db.insert('tasbih_records', {
          'title': 'Elhamdülillah',
          'arabic': 'ٱلْحَمْدُ لِلَّهِ',
          'count': 0,
          'target': 33,
          'is_custom': 0,
        });
        await db.insert('tasbih_records', {
          'title': 'Allahü Ekber',
          'arabic': 'ٱللَّهُ أَكْبَرُ',
          'count': 0,
          'target': 33,
          'is_custom': 0,
        });
        await db.insert('tasbih_records', {
          'title': 'Lâ ilâhe illallah',
          'arabic': 'لَا إِلَـٰهَ إِلَّا ٱللَّهُ',
          'count': 0,
          'target': 100,
          'is_custom': 0,
        });
      },
    );
  }

  static const List<String> _trSurahNames = [
    "Fâtiha", "Bakara", "Âl-i İmrân", "Nisâ", "Mâide", "En'âm", "A'râf", "Enfâl", "Tevbe", "Yûnus",
    "Hûd", "Yûsuf", "Ra'd", "İbrâhîm", "Hicr", "Nahl", "İsrâ", "Kehf", "Meryem", "Tâhâ",
    "Enbiyâ", "Hac", "Mü'minûn", "Nûr", "Furkân", "Şuarâ", "Neml", "Kasas", "Ankebût", "Rûm",
    "Lokmân", "Secde", "Ahzâb", "Sebe'", "Fâtır", "Yâsîn", "Sâffât", "Sâd", "Zümer", "Mü'min",
    "Fussilet", "Şûrâ", "Zuhruf", "Duhân", "Câsiye", "Ahkâf", "Muhammed", "Fetih", "Hucurât", "Kâf",
    "Zâriyât", "Tûr", "Necm", "Kamer", "Rahmân", "Vâkıa", "Hadîd", "Mücâdele", "Haşr", "Mümtehine",
    "Saf", "Cuma", "Münâfikûn", "Teğâbün", "Talâk", "Tahrîm", "Mülk", "Kalem", "Hâkka", "Meâric",
    "Nûh", "Cin", "Müzzemmil", "Müddessir", "Kıyâme", "İnsân", "Mürselât", "Nebe'", "Nâziât", "Abese",
    "Tekvîr", "İnfitâr", "Mutaffifîn", "İnşikâk", "Bürûc", "Târık", "A'lâ", "Gâşiye", "Fecr", "Beled",
    "Şems", "Leyl", "Duhâ", "İnşirâh", "Tîn", "Alak", "Kadr", "Beyyine", "Zilzâl", "Âdiyât",
    "Kâria", "Tekâsür", "Asr", "Hümeze", "Fîl", "Kureyş", "Mâûn", "Kevser", "Kâfirûn", "Nasr",
    "Tebbet", "İhlâs", "Felak", "Nâs"
  ];

  static const List<int> _surahAyahCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
    5, 4, 5, 6
  ];

  Future<List<SurahMeta>> fetchAllSurahs() async {
    return List.generate(114, (i) {
      return SurahMeta(
        number: i + 1,
        nameArabic: "سورة",
        nameTurkish: "${_trSurahNames[i]} Sûresi",
        ayahCount: _surahAyahCounts[i],
        revelationType: "Kur'ân-ı Kerîm",
      );
    });
  }

  // %100 AÇILMA GARANTİLİ KURAN SURESİ GETİRİCİ (Önbellek -> Birincil API -> Yedek API -> Gömülü Havuz)
  Future<List<LiveAyahItem>> fetchSurahAyahs(int surahNumber) async {
    final trSurahTitle = (surahNumber >= 1 && surahNumber <= 114)
        ? "${_trSurahNames[surahNumber - 1]} Sûresi"
        : "Sûre $surahNumber";

    try {
      final db = await database;
      final cached = await db.query(
        'cached_surahs',
        where: 'surah_number = ?',
        whereArgs: [surahNumber],
      );

      if (cached.isNotEmpty) {
        final rawList = jsonDecode(cached.first['payload'] as String) as List<dynamic>;
        if (rawList.isNotEmpty) {
          return rawList
              .map((e) => LiveAyahItem.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }

      // Birincil API: AlQuran Cloud
      final url =
          'https://api.alquran.cloud/v1/surah/$surahNumber/editions/quran-uthmani,tr.diyanet,ar.alafasy';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 7));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final editions = decoded['data'] as List<dynamic>;
        final arabicAyahs = (editions[0] as Map<String, dynamic>)['ayahs'] as List<dynamic>;
        final turkishAyahs = (editions[1] as Map<String, dynamic>)['ayahs'] as List<dynamic>;
        final audioAyahs = (editions[2] as Map<String, dynamic>)['ayahs'] as List<dynamic>;

        final List<LiveAyahItem> result = [];
        for (int i = 0; i < arabicAyahs.length; i++) {
          final ar = arabicAyahs[i] as Map<String, dynamic>;
          final tr = turkishAyahs[i] as Map<String, dynamic>;
          final au = audioAyahs[i] as Map<String, dynamic>;
          final globalNum = int.tryParse(ar['number'].toString()) ?? (i + 1);
          final inSurah = int.tryParse(ar['numberInSurah'].toString()) ?? (i + 1);

          result.add(
            LiveAyahItem(
              globalNumber: globalNum,
              numberInSurah: inSurah,
              surahNumber: surahNumber,
              surahName: trSurahTitle,
              arabicText: (ar['text'] ?? '').toString(),
              turkishText: (tr['text'] ?? '').toString(),
              audioUrl: (au['audio'] ??
                      'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalNum.mp3')
                  .toString(),
            ),
          );
        }

        if (result.isNotEmpty) {
          await db.insert(
            'cached_surahs',
            {
              'surah_number': surahNumber,
              'payload': jsonEncode(result.map((e) => e.toJson()).toList()),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          return result;
        }
      }
    } catch (_) {}

    // Yedek API: Quran.com V4
    try {
      final backupUrl =
          'https://api.quran.com/api/v4/quran/verses/uthmani?chapter_number=$surahNumber';
      final trBackupUrl =
          'https://api.quran.com/api/v4/quran/translations/77?chapter_number=$surahNumber';
      final resAr = await http.get(Uri.parse(backupUrl)).timeout(const Duration(seconds: 6));
      final resTr = await http.get(Uri.parse(trBackupUrl)).timeout(const Duration(seconds: 6));

      if (resAr.statusCode == 200 && resTr.statusCode == 200) {
        final versesAr = (jsonDecode(resAr.body)['verses'] as List<dynamic>);
        final versesTr = (jsonDecode(resTr.body)['translations'] as List<dynamic>);
        final List<LiveAyahItem> backupResult = [];
        for (int i = 0; i < versesAr.length; i++) {
          final arObj = versesAr[i] as Map<String, dynamic>;
          final trObj = (i < versesTr.length) ? (versesTr[i] as Map<String, dynamic>) : {};
          final id = int.tryParse(arObj['id'].toString()) ?? (i + 1);
          backupResult.add(
            LiveAyahItem(
              globalNumber: id,
              numberInSurah: i + 1,
              surahNumber: surahNumber,
              surahName: trSurahTitle,
              arabicText: (arObj['text_uthmani'] ?? '').toString(),
              turkishText: (trObj['text'] ?? '')
                  .toString()
                  .replaceAll(RegExp(r'<[^>]*>'), ''),
              audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$id.mp3',
            ),
          );
        }
        if (backupResult.isNotEmpty) return backupResult;
      }
    } catch (_) {}

    // %100 Garantili Gömülü Veri
    return OfflineSacredRepository.getFallbackSurah(surahNumber, trSurahTitle);
  }

  static const List<BibleBookMeta> kAllBibleBooks = [
    BibleBookMeta(bookId: 1, testament: 'torah', nameTurkish: 'Yaratılış (Tekvin)', sefariaName: 'Genesis', totalChapters: 50),
    BibleBookMeta(bookId: 2, testament: 'torah', nameTurkish: 'Mısır\'dan Çıkış (Şemot)', sefariaName: 'Exodus', totalChapters: 40),
    BibleBookMeta(bookId: 3, testament: 'torah', nameTurkish: 'Levililer (Vayikra)', sefariaName: 'Leviticus', totalChapters: 27),
    BibleBookMeta(bookId: 4, testament: 'torah', nameTurkish: 'Çölde Sayım (Bamidbar)', sefariaName: 'Numbers', totalChapters: 36),
    BibleBookMeta(bookId: 5, testament: 'torah', nameTurkish: 'Yasa\'nın Tekrarı (Devarim)', sefariaName: 'Deuteronomy', totalChapters: 34),
    BibleBookMeta(bookId: 6, testament: 'torah', nameTurkish: 'Yeşu', sefariaName: 'Joshua', totalChapters: 24),
    BibleBookMeta(bookId: 7, testament: 'torah', nameTurkish: 'Hâkimler', sefariaName: 'Judges', totalChapters: 21),
    BibleBookMeta(bookId: 8, testament: 'torah', nameTurkish: 'Rut', sefariaName: 'Ruth', totalChapters: 4),
    BibleBookMeta(bookId: 9, testament: 'torah', nameTurkish: '1. Samuel', sefariaName: 'I_Samuel', totalChapters: 31),
    BibleBookMeta(bookId: 10, testament: 'torah', nameTurkish: '2. Samuel', sefariaName: 'II_Samuel', totalChapters: 24),
    BibleBookMeta(bookId: 11, testament: 'torah', nameTurkish: '1. Krallar', sefariaName: 'I_Kings', totalChapters: 22),
    BibleBookMeta(bookId: 12, testament: 'torah', nameTurkish: '2. Krallar', sefariaName: 'II_Kings', totalChapters: 25),
    BibleBookMeta(bookId: 13, testament: 'torah', nameTurkish: '1. Tarihler', sefariaName: 'I_Chronicles', totalChapters: 29),
    BibleBookMeta(bookId: 14, testament: 'torah', nameTurkish: '2. Tarihler', sefariaName: 'II_Chronicles', totalChapters: 36),
    BibleBookMeta(bookId: 15, testament: 'torah', nameTurkish: 'Ezra', sefariaName: 'Ezra', totalChapters: 10),
    BibleBookMeta(bookId: 16, testament: 'torah', nameTurkish: 'Nehemya', sefariaName: 'Nehemiah', totalChapters: 13),
    BibleBookMeta(bookId: 17, testament: 'torah', nameTurkish: 'Ester', sefariaName: 'Esther', totalChapters: 10),
    BibleBookMeta(bookId: 18, testament: 'torah', nameTurkish: 'Eyüp', sefariaName: 'Job', totalChapters: 42),
    BibleBookMeta(bookId: 19, testament: 'torah', nameTurkish: 'Mezmurlar (Zebur)', sefariaName: 'Psalms', totalChapters: 150),
    BibleBookMeta(bookId: 20, testament: 'torah', nameTurkish: 'Süleyman\'ın Özdeyişleri', sefariaName: 'Proverbs', totalChapters: 31),
    BibleBookMeta(bookId: 21, testament: 'torah', nameTurkish: 'Vaiz', sefariaName: 'Ecclesiastes', totalChapters: 12),
    BibleBookMeta(bookId: 22, testament: 'torah', nameTurkish: 'Ezgiler Ezgisi', sefariaName: 'Song_of_Songs', totalChapters: 8),
    BibleBookMeta(bookId: 23, testament: 'torah', nameTurkish: 'Yeşaya', sefariaName: 'Isaiah', totalChapters: 66),
    BibleBookMeta(bookId: 24, testament: 'torah', nameTurkish: 'Yeremya', sefariaName: 'Jeremiah', totalChapters: 52),
    BibleBookMeta(bookId: 25, testament: 'torah', nameTurkish: 'Ağıtlar', sefariaName: 'Lamentations', totalChapters: 5),
    BibleBookMeta(bookId: 26, testament: 'torah', nameTurkish: 'Hezekiel', sefariaName: 'Ezekiel', totalChapters: 48),
    BibleBookMeta(bookId: 27, testament: 'torah', nameTurkish: 'Daniel', sefariaName: 'Daniel', totalChapters: 12),
    BibleBookMeta(bookId: 28, testament: 'torah', nameTurkish: 'Hoşea', sefariaName: 'Hosea', totalChapters: 14),
    BibleBookMeta(bookId: 29, testament: 'torah', nameTurkish: 'Yoel', sefariaName: 'Joel', totalChapters: 3),
    BibleBookMeta(bookId: 30, testament: 'torah', nameTurkish: 'Amos', sefariaName: 'Amos', totalChapters: 9),
    BibleBookMeta(bookId: 31, testament: 'torah', nameTurkish: 'Ovadya', sefariaName: 'Obadiah', totalChapters: 1),
    BibleBookMeta(bookId: 32, testament: 'torah', nameTurkish: 'Yunus', sefariaName: 'Jonah', totalChapters: 4),
    BibleBookMeta(bookId: 33, testament: 'torah', nameTurkish: 'Mika', sefariaName: 'Micah', totalChapters: 7),
    BibleBookMeta(bookId: 34, testament: 'torah', nameTurkish: 'Nahum', sefariaName: 'Nahum', totalChapters: 3),
    BibleBookMeta(bookId: 35, testament: 'torah', nameTurkish: 'Habakkuk', sefariaName: 'Habakkuk', totalChapters: 3),
    BibleBookMeta(bookId: 36, testament: 'torah', nameTurkish: 'Sefanya', sefariaName: 'Zephaniah', totalChapters: 3),
    BibleBookMeta(bookId: 37, testament: 'torah', nameTurkish: 'Hagay', sefariaName: 'Haggai', totalChapters: 2),
    BibleBookMeta(bookId: 38, testament: 'torah', nameTurkish: 'Zekeriya', sefariaName: 'Zechariah', totalChapters: 14),
    BibleBookMeta(bookId: 39, testament: 'torah', nameTurkish: 'Malaki', sefariaName: 'Malachi', totalChapters: 4),
    BibleBookMeta(bookId: 40, testament: 'gospel', nameTurkish: 'Matta İncili', sefariaName: 'Matthew', totalChapters: 28),
    BibleBookMeta(bookId: 41, testament: 'gospel', nameTurkish: 'Markos İncili', sefariaName: 'Mark', totalChapters: 16),
    BibleBookMeta(bookId: 42, testament: 'gospel', nameTurkish: 'Luka İncili', sefariaName: 'Luke', totalChapters: 24),
    BibleBookMeta(bookId: 43, testament: 'gospel', nameTurkish: 'Yuhanna İncili', sefariaName: 'John', totalChapters: 21),
    BibleBookMeta(bookId: 44, testament: 'gospel', nameTurkish: 'Elçilerin İşleri', sefariaName: 'Acts', totalChapters: 28),
    BibleBookMeta(bookId: 45, testament: 'gospel', nameTurkish: 'Romalılar', sefariaName: 'Romans', totalChapters: 16),
    BibleBookMeta(bookId: 46, testament: 'gospel', nameTurkish: '1. Korintliler', sefariaName: '1_Corinthians', totalChapters: 16),
    BibleBookMeta(bookId: 47, testament: 'gospel', nameTurkish: '2. Korintliler', sefariaName: '2_Corinthians', totalChapters: 13),
    BibleBookMeta(bookId: 48, testament: 'gospel', nameTurkish: 'Galatyalılar', sefariaName: 'Galatians', totalChapters: 6),
    BibleBookMeta(bookId: 49, testament: 'gospel', nameTurkish: 'Efesliler', sefariaName: 'Ephesians', totalChapters: 6),
    BibleBookMeta(bookId: 50, testament: 'gospel', nameTurkish: 'Filipililer', sefariaName: 'Philippians', totalChapters: 4),
    BibleBookMeta(bookId: 51, testament: 'gospel', nameTurkish: 'Koloseliler', sefariaName: 'Colossians', totalChapters: 4),
    BibleBookMeta(bookId: 52, testament: 'gospel', nameTurkish: '1. Selanikliler', sefariaName: '1_Thessalonians', totalChapters: 5),
    BibleBookMeta(bookId: 53, testament: 'gospel', nameTurkish: '2. Selanikliler', sefariaName: '2_Thessalonians', totalChapters: 3),
    BibleBookMeta(bookId: 54, testament: 'gospel', nameTurkish: '1. Timoteos', sefariaName: '1_Timothy', totalChapters: 6),
    BibleBookMeta(bookId: 55, testament: 'gospel', nameTurkish: '2. Timoteos', sefariaName: '2_Timothy', totalChapters: 4),
    BibleBookMeta(bookId: 56, testament: 'gospel', nameTurkish: 'Titus', sefariaName: 'Titus', totalChapters: 3),
    BibleBookMeta(bookId: 57, testament: 'gospel', nameTurkish: 'Filimon', sefariaName: 'Philemon', totalChapters: 1),
    BibleBookMeta(bookId: 58, testament: 'gospel', nameTurkish: 'İbraniler', sefariaName: 'Hebrews', totalChapters: 13),
    BibleBookMeta(bookId: 59, testament: 'gospel', nameTurkish: 'Yakup', sefariaName: 'James', totalChapters: 5),
    BibleBookMeta(bookId: 60, testament: 'gospel', nameTurkish: '1. Petrus', sefariaName: '1_Peter', totalChapters: 5),
    BibleBookMeta(bookId: 61, testament: 'gospel', nameTurkish: '2. Petrus', sefariaName: '2_Peter', totalChapters: 3),
    BibleBookMeta(bookId: 62, testament: 'gospel', nameTurkish: '1. Yuhanna', sefariaName: '1_John', totalChapters: 5),
    BibleBookMeta(bookId: 63, testament: 'gospel', nameTurkish: '2. Yuhanna', sefariaName: '2_John', totalChapters: 1),
    BibleBookMeta(bookId: 64, testament: 'gospel', nameTurkish: '3. Yuhanna', sefariaName: '3_John', totalChapters: 1),
    BibleBookMeta(bookId: 65, testament: 'gospel', nameTurkish: 'Yahuda', sefariaName: 'Jude', totalChapters: 1),
    BibleBookMeta(bookId: 66, testament: 'gospel', nameTurkish: 'Vahiy (Esinleme)', sefariaName: 'Revelation', totalChapters: 22),
  ];

  // %100 AÇILMA GARANTİLİ TEVRAT & İNCİL GETİRİCİ (Asla Boş Dönmez)
  Future<List<BibleVerseItem>> fetchBibleChapter(BibleBookMeta book, int chapter) async {
    try {
      final db = await database;
      final key = '${book.bookId}_$chapter';
      final cached = await db.query(
        'cached_bible_chapters',
        where: 'cache_key = ?',
        whereArgs: [key],
      );

      if (cached.isNotEmpty) {
        final list = jsonDecode(cached.first['payload'] as String) as List<dynamic>;
        if (list.isNotEmpty) {
          return list.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return BibleVerseItem(
              bookId: int.tryParse(m['bookId'].toString()) ?? book.bookId,
              bookName: m['bookName'].toString(),
              chapter: int.tryParse(m['chapter'].toString()) ?? chapter,
              verse: int.tryParse(m['verse'].toString()) ?? 1,
              originalScript: m['originalScript'].toString(),
              turkishText: m['turkishText'].toString(),
            );
          }).toList();
        }
      }

      final trUrl = 'https://bolls.life/get-text/TCL02/${book.bookId}/$chapter/';
      final trRes = await http.get(Uri.parse(trUrl)).timeout(const Duration(seconds: 6));

      List<String> hebrewList = [];
      if (book.testament == 'torah') {
        try {
          final sefRes = await http
              .get(Uri.parse('https://www.sefaria.org/api/texts/${book.sefariaName}.$chapter?context=0'))
              .timeout(const Duration(seconds: 4));
          if (sefRes.statusCode == 200) {
            final sefMap = jsonDecode(sefRes.body) as Map<String, dynamic>;
            final he = sefMap['he'];
            if (he is List) {
              hebrewList = he.map((e) => e.toString().replaceAll(RegExp(r'<[^>]*>'), '')).toList();
            }
          }
        } catch (_) {}
      }

      if (trRes.statusCode == 200) {
        final decodedBody = jsonDecode(trRes.body);
        if (decodedBody is List && decodedBody.isNotEmpty) {
          final List<BibleVerseItem> verses = [];
          for (int i = 0; i < decodedBody.length; i++) {
            final item = Map<String, dynamic>.from(decodedBody[i] as Map);
            final vNum = int.tryParse(item['verse'].toString()) ?? (i + 1);
            final cleanTr = (item['text'] ?? '')
                .toString()
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .trim();
            final orig = (i < hebrewList.length) ? hebrewList[i] : '';

            if (cleanTr.isNotEmpty) {
              verses.add(
                BibleVerseItem(
                  bookId: book.bookId,
                  bookName: book.nameTurkish,
                  chapter: chapter,
                  verse: vNum,
                  originalScript: orig,
                  turkishText: cleanTr,
                ),
              );
            }
          }

          if (verses.isNotEmpty) {
            await db.insert(
              'cached_bible_chapters',
              {
                'cache_key': key,
                'payload': jsonEncode(
                  verses
                      .map((v) => {
                            'bookId': v.bookId,
                            'bookName': v.bookName,
                            'chapter': v.chapter,
                            'verse': v.verse,
                            'originalScript': v.originalScript,
                            'turkishText': v.turkishText,
                          })
                      .toList(),
                ),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            return verses;
          }
        }
      }
    } catch (_) {}

    // API yanıt vermezse veya zaman aşımına uğrarsa anında gömülü metni döndür
    return OfflineSacredRepository.getFallbackBibleChapter(book, chapter);
  }

  Future<List<EsmaItem>> fetchEsmaulHusna() async {
    try {
      final res = await http
          .get(Uri.parse('https://api.aladhan.com/v1/asmaAlHusna'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        final data = map['data'] as List<dynamic>;
        return data.map((e) {
          final item = e as Map<String, dynamic>;
          final num = int.tryParse(item['number'].toString()) ?? 1;
          final en = (item['en'] as Map<String, dynamic>)['meaning'].toString();
          return EsmaItem(
            number: num,
            arabic: item['name'].toString(),
            transliteration: item['transliteration'].toString(),
            turkishMeaning: _turkishEsmaMeaning(num, en),
            ebcedValue: _ebcedForEsma(num),
          );
        }).toList();
      }
    } catch (_) {}

    return List.generate(99, (index) {
      final n = index + 1;
      return EsmaItem(
        number: n,
        arabic: "ٱللَّهُ",
        transliteration: "Esma #$n",
        turkishMeaning: _turkishEsmaMeaning(n, "İlahi Kemâl Sıfatı"),
        ebcedValue: _ebcedForEsma(n),
      );
    });
  }

  static int _ebcedForEsma(int n) {
    const ebceds = [
      66, 298, 258, 90, 170, 131, 136, 145, 94, 206,
      213, 684, 336, 1281, 306, 14, 731, 489, 150, 903,
      72, 148, 576, 66, 770, 180, 75, 104, 129, 302,
      88, 1020, 68, 1286, 526, 110, 232, 86, 80, 40,
      73, 412, 270, 55, 137, 48, 300, 57, 319, 109,
      108, 110, 116, 500, 156, 550, 49, 58, 69, 68,
      61, 490, 18, 14, 65, 162, 46, 134, 305, 184,
      188, 84, 37, 801, 1000, 106, 551, 47, 74, 80,
      156, 287, 1098, 256, 1100, 209, 114, 1100, 1060, 100,
      1019, 91, 256, 298, 62, 180, 707, 514, 298
    ];
    return ebceds[(n - 1) % ebceds.length];
  }

  static String _turkishEsmaMeaning(int n, String fallback) {
    const tr = {
      1: "Kendisinden başka ilah bulunmayan tek ve mutlak Yaratıcı.",
      2: "Dünyada bütün mahlûkata merhamet eden ve rızık veren (Er-Rahmân).",
      3: "Ahirette müminlere sonsuz ikramda bulunan (Er-Rahîm).",
      4: "Kâinatın tek ve gerçek sahibi, mutlak hükümdarı (El-Melik).",
      5: "Her noksanlıktan münezzeh ve tertemiz olan (El-Kuddûs).",
      6: "Kullarını selâmete ve içsel sükûnete çıkaran (Es-Selâm).",
      19: "Her türlü müşkülü çözen ve hayır kapılarını açan (El-Fettâh).",
      20: "Gizli ve açık her şeyi hakkıyla bilen (El-Alîm).",
      63: "Ezeli ve ebedi diri, hayatın mutlak kaynağı (El-Hayy).",
      64: "Gökleri, yeri ve tüm varlığı her an ayakta tutan (El-Kayyûm).",
      93: "Alemleri ve kalpleri nurlandıran (En-Nûr).",
    };
    return tr[n] ?? "İlahi tecelli ve esma sırrı ($fallback)";
  }

  static const List<HourlyShortVerse> kHourlyShortVerses = [
    HourlyShortVerse(index: 0, ayahKey: "93:3", arabicShort: "مَا وَدَّعَكَ رَبُّكَ", turkishShort: "Rabbin seni terk etmedi.", reference: "Duhâ, 3"),
    HourlyShortVerse(index: 1, ayahKey: "94:6", arabicShort: "إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا", turkishShort: "Zorlukla beraber kolaylık vardır.", reference: "İnşirah, 6"),
    HourlyShortVerse(index: 2, ayahKey: "2:153", arabicShort: "إِنَّ ٱللَّهَ مَعَ ٱلصَّـٰبِرِينَ", turkishShort: "Allah sabredenlerle beraberdir.", reference: "Bakara, 153"),
    HourlyShortVerse(index: 3, ayahKey: "9:40", arabicShort: "لَا تَحْزَنْ إِنَّ ٱللَّهَ مَعَنَا", turkishShort: "Üzülme! Allah bizimledir.", reference: "Tevbe, 40"),
    HourlyShortVerse(index: 4, ayahKey: "2:152", arabicShort: "فَٱذْكُرُونِىٓ أَذْكُرْكُمْ", turkishShort: "Beni anın ki sizi anayım.", reference: "Bakara, 152"),
    HourlyShortVerse(index: 5, ayahKey: "67:1", arabicShort: "وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ", turkishShort: "O, her şeye kadirdir.", reference: "Mülk, 1"),
    HourlyShortVerse(index: 6, ayahKey: "3:185", arabicShort: "كُلُّ نَفْسٍ ذَآئِقَةُ ٱلْمَوْتِ", turkishShort: "Her nefis ölümü tadacaktır.", reference: "Âl-i İmrân, 185"),
    HourlyShortVerse(index: 7, ayahKey: "13:28", arabicShort: "أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ", turkishShort: "Kalpler Allah'ı anmakla huzur bulur.", reference: "Ra'd, 28"),
    HourlyShortVerse(index: 8, ayahKey: "50:16", arabicShort: "وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ ٱلْوَرِيدِ", turkishShort: "Biz ona şah damarından yakınız.", reference: "Kâf, 16"),
    HourlyShortVerse(index: 9, ayahKey: "39:53", arabicShort: "لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ", turkishShort: "Allah'ın rahmetinden ümit kesmeyin.", reference: "Zümer, 53"),
    HourlyShortVerse(index: 10, ayahKey: "93:5", arabicShort: "وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ", turkishShort: "Rabbin sana verecek ve razı olacaksın.", reference: "Duhâ, 5"),
    HourlyShortVerse(index: 11, ayahKey: "3:173", arabicShort: "حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ", turkishShort: "Allah bize yeter, O ne güzel vekildir.", reference: "Âl-i İmrân, 173"),
    HourlyShortVerse(index: 12, ayahKey: "40:60", arabicShort: "ٱدْعُونِىٓ أَسْتَجِبْ لَكُمْ", turkishShort: "Bana dua edin, size icabet edeyim.", reference: "Mü'min, 60"),
    HourlyShortVerse(index: 13, ayahKey: "2:186", arabicShort: "فَإِنِّى قَرِيبٌ", turkishShort: "Şüphesiz Ben çok yakınım.", reference: "Bakara, 186"),
    HourlyShortVerse(index: 14, ayahKey: "14:7", arabicShort: "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ", turkishShort: "Şükrederseniz nimetimi artırırım.", reference: "İbrâhîm, 7"),
    HourlyShortVerse(index: 15, ayahKey: "65:3", arabicShort: "وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥ", turkishShort: "Allah'a tevekkül edene O yeter.", reference: "Talâk, 3"),
    HourlyShortVerse(index: 16, ayahKey: "1:5", arabicShort: "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", turkishShort: "Yalnız Sana kulluk ederiz.", reference: "Fâtiha, 5"),
    HourlyShortVerse(index: 17, ayahKey: "57:4", arabicShort: "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ", turkishShort: "Nerede olursanız olun O sizinledir.", reference: "Hadîd, 4"),
    HourlyShortVerse(index: 18, ayahKey: "2:286", arabicShort: "لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا", turkishShort: "Allah kimseye gücünden fazlasını yüklemez.", reference: "Bakara, 286"),
    HourlyShortVerse(index: 19, ayahKey: "94:8", arabicShort: "وَإِلَىٰ رَبِّكَ فَٱرْغَب", turkishShort: "Yalnızca Rabbine yönel.", reference: "İnşirah, 8"),
    HourlyShortVerse(index: 20, ayahKey: "36:82", arabicShort: "أَن يَقُولَ لَهُۥ كُن فَيَكُونُ", turkishShort: "O'nun emri 'Ol!' demektir, hemen olur.", reference: "Yâsîn, 82"),
    HourlyShortVerse(index: 21, ayahKey: "24:35", arabicShort: "ٱللَّهُ نُورُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ", turkishShort: "Allah göklerin ve yerin nûrudur.", reference: "Nûr, 35"),
    HourlyShortVerse(index: 22, ayahKey: "51:50", arabicShort: "فَفِرُّوٓا۟ إِلَى ٱللَّهِ", turkishShort: "Öyleyse Allah'a koşun!", reference: "Zâriyât, 50"),
    HourlyShortVerse(index: 23, ayahKey: "3:159", arabicShort: "إِنَّ ٱللَّهَ يُحِبُّ ٱلْمُتَوَكِّلِينَ", turkishShort: "Allah tevekkül edenleri sever.", reference: "Âl-i İmrân, 159"),
    HourlyShortVerse(index: 24, ayahKey: "2:195", arabicShort: "إِنَّ ٱللَّهَ يُحِبُّ ٱلْمُحْسِنِينَ", turkishShort: "Allah iyilik edenleri sever.", reference: "Bakara, 195"),
    HourlyShortVerse(index: 25, ayahKey: "99:7", arabicShort: "فَمَن يَعْمَلْ مِثْقَالَ ذَرَّةٍ خَيْرًا يَرَهُۥ", turkishShort: "Zerre kadar iyilik yapan karşılığını görür.", reference: "Zilzâl, 7"),
    HourlyShortVerse(index: 26, ayahKey: "112:1", arabicShort: "قُلْ هُوَ ٱللَّهُ أَحَدٌ", turkishShort: "De ki: O Allah tektir.", reference: "İhlâs, 1"),
    HourlyShortVerse(index: 27, ayahKey: "112:2", arabicShort: "ٱللَّهُ ٱلصَّمَدُ", turkishShort: "Her şey O'na muhtaçtır.", reference: "İhlâs, 2"),
    HourlyShortVerse(index: 28, ayahKey: "65:7", arabicShort: "سَيَجْعَلُ ٱللَّهُ بَعْدَ عُسْرٍ يُسْرًا", turkishShort: "Allah zorluğun ardından kolaylık verir.", reference: "Talâk, 7"),
    HourlyShortVerse(index: 29, ayahKey: "19:64", arabicShort: "وَمَا كَانَ رَبُّكَ نَسِيًّا", turkishShort: "Senin Rabbin asla unutkan değildir.", reference: "Meryem, 64"),
    HourlyShortVerse(index: 30, ayahKey: "7:156", arabicShort: "وَرَحْمَتِى وَسِعَتْ كُلَّ شَىْءٍ", turkishShort: "Rahmetim her şeyi kuşatmıştır.", reference: "A'râf, 156"),
    HourlyShortVerse(index: 31, ayahKey: "42:19", arabicShort: "ٱللَّهُ لَطِيفٌۢ بِعِبَادِهِۦ", turkishShort: "Allah kullarına çok lütufkârdır.", reference: "Şûrâ, 19"),
    HourlyShortVerse(index: 32, ayahKey: "2:156", arabicShort: "إِنَّا لِلَّهِ وَإِنَّآ إِلَيْهِ رَٰجِعُونَ", turkishShort: "Biz Allah'a aidiz ve O'na döneceğiz.", reference: "Bakara, 156"),
  ];

  static const List<CrossReferenceTopic> kCrossReferenceTopics = [
    CrossReferenceTopic(
      id: "cr_1",
      topic: "1. Yoktan Yaratılış ve İlahi 'Ol' Emri",
      summary: "Üç ilahi metinde evrenin yokluktan var edilişi ve İlahi Kelam/Nur metaforu.",
      quranKey: "Yâsîn 36:82 & Nûr 24:35",
      torahRef: "Yaratılış (Tekvin) 1:1-3",
      gospelRef: "Yuhanna 1:1-5",
      quranText: "Bir şeyi dilediğinde O'nun emri yalnızca 'Ol!' demektir, o da hemen oluverir. Allah göklerin ve yerin nûrudur.",
      torahText: "Başlangıçta Tanrı göğü ve yeri yarattı. Tanrı 'Işık olsun' diye buyurdu ve ışık oldu.",
      gospelText: "Başlangıçta Söz vardı, Söz Tanrı'yla birlikteydi. Yaşam insanların ışığıydı ve karanlık onu alt edemedi.",
    ),
    CrossReferenceTopic(
      id: "cr_2",
      topic: "2. Hz. İbrahim'in İmanı ve Teslimiyeti",
      summary: "Tevhid babası Hz. İbrahim'in koşulsuz imanı ve tek Yaratıcıya yönelişi.",
      quranKey: "Bakara 2:131 & En'âm 6:79",
      torahRef: "Yaratılış (Tekvin) 15:6",
      gospelRef: "Romalılar 4:3 & Yakup 2:23",
      quranText: "Rabbi ona 'İslam ol (teslim ol)' dediğinde, 'Âlemlerin Rabbine teslim oldum' dedi.",
      torahText: "Avram RAB'be iman etti ve RAB bunu ona doğruluk saydı.",
      gospelText: "İbrahim Tanrı'ya iman etti ve kendisine Tanrı'nın dostu dendi.",
    ),
    CrossReferenceTopic(
      id: "cr_3",
      topic: "3. Hz. Musa ve Mukaddes Vadi (Yanan Çalı)",
      summary: "Sina/Tuvâ vadisinde ilahi hitap ve çarıkların çıkarılması emri.",
      quranKey: "Tâhâ 20:11-12",
      torahRef: "Mısır'dan Çıkış 3:4-5",
      gospelRef: "Elçilerin İşleri 7:33",
      quranText: "Ey Musa! Şüphesiz Ben senin Rabbinim. Hemen pabuçlarını çıkar; çünkü sen mukaddes Tuvâ vadisindesin.",
      torahText: "Tanrı çalının içinden seslendi: Çarığını çıkar, çünkü bastığın yer kutsal topraktır.",
      gospelText: "Rab ona şöyle dedi: Ayakkabılarını çıkar, çünkü bastığın yer kutsal topraktır.",
    ),
    CrossReferenceTopic(
      id: "cr_4",
      topic: "4. Kızıldeniz'in Yarılması Mucizesi",
      summary: "Firavun ordusuna karşı denizin ikiye ayrılması ve inananların kurtuluşu.",
      quranKey: "Şuarâ 26:63",
      torahRef: "Mısır'dan Çıkış 14:21-22",
      gospelRef: "İbraniler 11:29",
      quranText: "Musa'ya 'Asân ile denize vur!' diye vahyettik. Deniz derhal yarıldı, her parçası koca bir dağ gibi oldu.",
      torahText: "Musa elini denizin üzerine uzattı; sular ikiye bölündü ve İsrailliler kuru toprak üzerinden geçtiler.",
      gospelText: "İman sayesinde Kızıldeniz'den kuru karadan geçer gibi geçtiler.",
    ),
    CrossReferenceTopic(
      id: "cr_5",
      topic: "5. Hz. Nuh ve Tufan Gemisi",
      summary: "Tufan öncesi uyarı, geminin inşası ve tufan sonrası ilahi selamet.",
      quranKey: "Hûd 11:44",
      torahRef: "Yaratılış (Tekvin) 8:1-4",
      gospelRef: "1. Petrus 3:20",
      quranText: "'Ey yer suyunu yut ve ey gök suyunu tut!' denildi. Su çekildi, iş bitirildi ve gemi Cûdî üzerine yerleşti.",
      torahText: "Tanrı Nuh'u ve gemidekileri anımsadı; sular çekildi ve gemi Ararat dağları üzerine oturdu.",
      gospelText: "Nuh'un günlerinde gemi yapılırken Tanrı sabırla bekledi ve gemidekiler suyla kurtuldu.",
    ),
    CrossReferenceTopic(
      id: "cr_6",
      topic: "6. Hz. İsa (Mesih) ve Meryem'e Müjde",
      summary: "Melek Cebrail'in Hz. Meryem'e mucizevi doğumu müjdelemesi.",
      quranKey: "Âl-i İmrân 3:45",
      torahRef: "Yeşaya 7:14",
      gospelRef: "Luka 1:30-31",
      quranText: "Melekler dedi ki: Ey Meryem! Allah seni kendisinden bir Kelime ile müjdeliyor; adı Meryem oğlu İsa Mesih'tir.",
      torahText: "İşte kız gebe kalacak, bir oğul doğuracak ve adını İmmanuel koyacak.",
      gospelText: "Melek ona, 'Korkma Meryem, Tanrı'nın lütfuna eriştin; gebe kalıp bir oğul doğuracaksın, adını İsa koyacaksın' dedi.",
    ),
    CrossReferenceTopic(
      id: "cr_7",
      topic: "7. On Emir ve Temel Ahlak Yasası",
      summary: "Tek Allah'a kulluk, anne-babaya iyilik, cana kıymama ve dürüstlük ilkeleri.",
      quranKey: "İsrâ 17:22-37",
      torahRef: "Mısır'dan Çıkış 20:1-17",
      gospelRef: "Matta 19:17-19",
      quranText: "O'ndan başkasına ibadet etmeyin, anne-babaya iyilik edin, haksız yere cana kıymayın, ölçü ve tartıyı tam yapın.",
      torahText: "Benden başka tanrın olmayacak. Annene babana saygı göster. Adam öldürmeyeceksin. Çalmayacaksın.",
      gospelText: "Adam öldürmeyeceksin, çalmayacaksın, yalan tanıklık etmeyeceksin, annene babana saygı göstereceksin.",
    ),
    CrossReferenceTopic(
      id: "cr_8",
      topic: "8. Hz. Davut, Zebur ve Dağların Tesbihi",
      summary: "Hz. Davut'un yakarışı ve yaratılmışların onunla birlikte tesbih etmesi.",
      quranKey: "Sebe' 34:10",
      torahRef: "Mezmurlar (Zebur) 148:7-10",
      gospelRef: "Elçilerin İşleri 13:22",
      quranText: "Andolsun Davut'a katımızdan bir üstünlük verdik: 'Ey dağlar ve kuşlar! Onunla beraber tesbih edin.'",
      torahText: "RAB'bi övün ey dağlar, bütün tepeler, meyve ağaçları ve bütün kanatlı kuşlar!",
      gospelText: "İşay oğlu Davut'u gönlüme uygun bir er olarak buldum.",
    ),
    CrossReferenceTopic(
      id: "cr_9",
      topic: "9. Hz. Süleyman ve İlahi Hikmet",
      summary: "Dünya mülkünün ötesinde Allah katındaki hikmet ve adaletin üstünlüğü.",
      quranKey: "Neml 27:15-19",
      torahRef: "1. Krallar 3:9-12",
      gospelRef: "Matta 12:42",
      quranText: "Andolsun biz Davut'a ve Süleyman'a ilim verdik. İkisi de 'Bizi üstün kılan Allah'a hamdolsun' dediler.",
      torahText: "Sana bilge ve anlayışlı bir yürek veriyorum; senden önce senin gibisi olmadı.",
      gospelText: "Güney Kraliçesi Süleyman'ın bilgeliğini dinlemek için dünyanın öbür ucundan geldi.",
    ),
    CrossReferenceTopic(
      id: "cr_10",
      topic: "10. Hz. Eyüp'ün Sabrı ve Şifası",
      summary: "Ağır imtihan karşısında sabır ve sonunda gelen ilahi rahmet.",
      quranKey: "Enbiyâ 21:83-84",
      torahRef: "Eyüp 42:10-12",
      gospelRef: "Yakup 5:11",
      quranText: "Eyüp Rabbine, 'Başıma bu dert geldi, Sen merhametlilerin en merhametlisisin' diye nida etti; biz de sıkıntısını giderdik.",
      torahText: "RAB Eyüp'ün önceki durumunu yeniden sağladı ve ona iki katını verdi.",
      gospelText: "Eyüp'ün sabrını duydunuz ve Rab'bin ne kadar şefkatli olduğunu gördünüz.",
    ),
  ];

  Future<List<TasbihRecord>> getTasbihRecords() async {
    final db = await database;
    final rows = await db.query('tasbih_records');
    return rows.map(TasbihRecord.fromMap).toList();
  }

  Future<void> updateTasbihCount(int id, int newCount) async {
    final db = await database;
    await db.update(
      'tasbih_records',
      {'count': newCount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addCustomTasbih(String title, String arabic, int target) async {
    final db = await database;
    await db.insert('tasbih_records', {
      'title': title,
      'arabic': arabic,
      'count': 0,
      'target': target,
      'is_custom': 1,
    });
  }
}
