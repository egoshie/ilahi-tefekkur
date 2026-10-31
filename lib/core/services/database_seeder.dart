import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/v42_models.dart';
import 'offline_sacred_repository.dart';

final databaseServiceProvider = Provider< DatabaseService >((ref) {
  return DatabaseService();
});

class DatabaseService {
  static Database? _db;

  Future< Database > get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future< Database > _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'huzur_v50_live_production.db');

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

  Future< List< SurahMeta > > fetchAllSurahs() async {
    return OfflineSacredRepository.getAllSurahMetadata();
  }

  Future< List< LiveAyahItem > > fetchSurahAyahs(int surahNumber) async {
    final trSurahTitle = (surahNumber >= 1 && surahNumber <= 114)
        ? "${OfflineSacredRepository.kSurahNamesTr[surahNumber - 1]} Sûresi"
        : "Sûre $surahNumber";

    try {
      final db = await database;
      final cached = await db.query(
        'cached_surahs',
        where: 'surah_number = ?',
        whereArgs: [surahNumber],
      );

      if (cached.isNotEmpty) {
        final rawList =
            jsonDecode(cached.first['payload'] as String) as List< dynamic >;
        if (rawList.isNotEmpty) {
          return rawList
              .map((e) => LiveAyahItem.fromJson(
                  Map< String, dynamic >.from(e as Map)))
              .toList();
        }
      }

      // 1. Birincil Canlı API: AlQuran Cloud (Arapça Hat + Diyanet Meal + Alafasy MP3)
      final url =
          'https://api.alquran.cloud/v1/surah/$surahNumber/editions/quran-uthmani,tr.yazir,ar.alafasy,tr.diyanet';
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map< String, dynamic >;
        final editions = decoded['data'] as List< dynamic >;
        final arabicAyahs =
            (editions[0] as Map< String, dynamic >)['ayahs'] as List< dynamic >;
        final turkishAyahs =
            (editions[1] as Map< String, dynamic >)['ayahs'] as List< dynamic >;
        final audioAyahs =
            (editions[2] as Map< String, dynamic >)['ayahs'] as List< dynamic >;

        final List< LiveAyahItem > result = [];
        final altTurkishAyahs = editions.length > 3
            ? ((editions[3] as Map< String, dynamic >)["ayahs"] as List< dynamic >)
            : turkishAyahs;
        String prevTrText = "";
        for (int i = 0; i < arabicAyahs.length; i++) {
          final ar = arabicAyahs[i] as Map< String, dynamic >;
          final tr = turkishAyahs[i] as Map< String, dynamic >;
          final altTr = altTurkishAyahs[i] as Map< String, dynamic >;
          final au = audioAyahs[i] as Map< String, dynamic >;
          final globalNum = int.tryParse(ar['number'].toString()) ?? (i + 1);
          final inSurah =
              int.tryParse(ar['numberInSurah'].toString()) ?? (i + 1);

          result.add(
            LiveAyahItem(
              globalNumber: globalNum,
              numberInSurah: inSurah,
              surahNumber: surahNumber,
              surahName: trSurahTitle,
              arabicText: (ar['text'] ?? '').toString(),
              turkishText: (() {
                String t1 = (tr['text'] ?? '').toString().trim();
                String t2 = (altTr['text'] ?? '').toString().trim();
                String chosen = (t1 == prevTrText && t2.isNotEmpty && t2 != prevTrText) ? t2 : t1;
                prevTrText = chosen;
                return chosen;
              })(),
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

    // 2. İkincil Canlı API: Quran.com V4
    try {
      final resAr = await http
          .get(Uri.parse(
              'https://api.quran.com/api/v4/quran/verses/uthmani?chapter_number=$surahNumber'))
          .timeout(const Duration(seconds: 10));
      final resTr = await http
          .get(Uri.parse(
              'https://api.quran.com/api/v4/quran/translations/77?chapter_number=$surahNumber'))
          .timeout(const Duration(seconds: 10));

      if (resAr.statusCode == 200 && resTr.statusCode == 200) {
        final versesAr = jsonDecode(resAr.body)['verses'] as List< dynamic >;
        final versesTr =
            jsonDecode(resTr.body)['translations'] as List< dynamic >;
        final List< LiveAyahItem > backup = [];
        for (int i = 0; i < versesAr.length; i++) {
          final arObj = versesAr[i] as Map< String, dynamic >;
          final trObj = (i < versesTr.length)
              ? (versesTr[i] as Map< String, dynamic >)
              : < String, dynamic >{};
          final id = int.tryParse(arObj['id'].toString()) ?? (i + 1);
          backup.add(
            LiveAyahItem(
              globalNumber: id,
              numberInSurah: i + 1,
              surahNumber: surahNumber,
              surahName: trSurahTitle,
              arabicText: (arObj['text_uthmani'] ?? '').toString(),
              turkishText: (trObj['text'] ?? '')
                  .toString()
                  .replaceAll(RegExp('<' '[^>]*>'), ''),
              audioUrl:
                  'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$id.mp3',
            ),
          );
        }
        if (backup.isNotEmpty) return backup;
      }
    } catch (_) {}

    return OfflineSacredRepository.getFallbackSurah(surahNumber, trSurahTitle);
  }

  static const List< BibleBookMeta > kAllBibleBooks = [
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

  // %100 CANLI MULTI-API TEVRAT & İNCİL GETİRİCİ (bolls.life -> Sefaria -> Bible-API)
  Future<List<BibleVerseItem>> fetchBibleChapter(BibleBookMeta book, int chapter) async {
    final db = await database;
    final key = "v50_live_tr_${book.bookId}_$chapter";
    try {
      final cached = await db.query("cached_bible_chapters", where: "cache_key = ?", whereArgs: [key]);
      if (cached.isNotEmpty) {
        final list = jsonDecode(cached.first["payload"] as String) as List<dynamic>;
        if (list.isNotEmpty) {
          return list.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return BibleVerseItem(
              bookId: int.tryParse(m["bookId"].toString()) ?? book.bookId,
              bookName: m["bookName"].toString(),
              chapter: int.tryParse(m["chapter"].toString()) ?? chapter,
              verse: int.tryParse(m["verse"].toString()) ?? 1,
              originalScript: m["originalScript"].toString(),
              turkishText: m["turkishText"].toString(),
            );
          }).toList();
        }
      }
    } catch (_) {}

    final headers = <String, String>{"Accept": "application/json", "User-Agent": "HuzurApp/5.0"};
    final Map<int, String> origMap = {};
    try {
      final origEdition = book.testament == "torah" ? "wlc" : "textusreceptus";
      final oRes = await http.get(Uri.parse("https://api.getbible.net/v2/\$origEdition/${book.bookId}/$chapter.json"), headers: headers).timeout(const Duration(seconds: 5));
      if (oRes.statusCode == 200) {
        final oJson = jsonDecode(utf8.decode(oRes.bodyBytes)) as Map<String, dynamic>;
        final oVerses = oJson["verses"];
        if (oVerses is List) {
          for (final item in oVerses) {
            final m = Map<String, dynamic>.from(item as Map);
            final vNum = int.tryParse(m["verse"].toString()) ?? 0;
            final txt = (m["text"] ?? "").toString().trim();
            if (vNum > 0 && txt.isNotEmpty) origMap[vNum] = txt;
          }
        }
      }
    } catch (_) {}

    for (final url in ["https://api.getbible.net/v2/turkish/${book.bookId}/$chapter.json", "https://cdn.jsdelivr.net/gh/getbible/v2@master/turkish/${book.bookId}/$chapter.json"]) {
      try {
        final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          final rawVerses = map["verses"];
          if (rawVerses is List && rawVerses.isNotEmpty) {
            final List<BibleVerseItem> verses = [];
            String prevTr = "";
            for (int i = 0; i < rawVerses.length; i++) {
              final row = Map<String, dynamic>.from(rawVerses[i] as Map);
              final vNum = int.tryParse(row["verse"].toString()) ?? (i + 1);
              final cleanTr = (row["text"] ?? "").toString().replaceAll(RegExp("<" "[^>]*>"), "").replaceAll(RegExp(r"\s+"), " ").trim();
              if (cleanTr.isNotEmpty && cleanTr != prevTr) {
                prevTr = cleanTr;
                verses.add(BibleVerseItem(bookId: book.bookId, bookName: book.nameTurkish, chapter: chapter, verse: vNum, originalScript: origMap[vNum] ?? "", turkishText: cleanTr));
              }
            }
            if (verses.isNotEmpty) {
              await _cacheBibleVerses(db, key, verses);
              return verses;
            }
          }
        }
      } catch (_) {}
    }

    for (final endpoint in ["https://bolls.life/get-text/TCL02/${book.bookId}/$chapter/", "https://bolls.life/get-text/TUR/${book.bookId}/$chapter/"]) {
      try {
        final trRes = await http.get(Uri.parse(endpoint), headers: headers).timeout(const Duration(seconds: 10));
        if (trRes.statusCode == 200) {
          final decodedBody = jsonDecode(utf8.decode(trRes.bodyBytes));
          if (decodedBody is List && decodedBody.isNotEmpty) {
            final List<BibleVerseItem> verses = [];
            String prevTr = "";
            for (int i = 0; i < decodedBody.length; i++) {
              final item = Map<String, dynamic>.from(decodedBody[i] as Map);
              final vNum = int.tryParse(item["verse"].toString()) ?? (i + 1);
              final cleanTr = (item["text"] ?? "").toString().replaceAll(RegExp("<" "[^>]*>"), "").replaceAll(RegExp(r"\s+"), " ").trim();
              if (cleanTr.isNotEmpty && cleanTr != prevTr) {
                prevTr = cleanTr;
                verses.add(BibleVerseItem(bookId: book.bookId, bookName: book.nameTurkish, chapter: chapter, verse: vNum, originalScript: origMap[vNum] ?? "", turkishText: cleanTr));
              }
            }
            if (verses.isNotEmpty) {
              await _cacheBibleVerses(db, key, verses);
              return verses;
            }
          }
        }
      } catch (_) {}
    }

    return OfflineSacredRepository.getFallbackBibleChapter(book, chapter);
  }

  Future< void > _cacheBibleVerses(
    Database db,
    String key,
    List< BibleVerseItem > verses,
  ) async {
    try {
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
    } catch (_) {}
  }

  Future< List< EsmaulHusnaItem > > fetchEsmaulHusna() async {
    return OfflineSacredRepository.kAll99EsmaulHusna;
  }

  static const List< HourlyShortVerse > kHourlyShortVerses =
      OfflineSacredRepository.kHourlyShortVerses;

  static const List< CrossReferenceTopic > kCrossReferenceTopics = [
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
      quranKey: "Bakara 2:131",
      torahRef: "Yaratılış (Tekvin) 15:6",
      gospelRef: "Yakup 2:23",
      quranText: "Rabbi ona 'İslam ol (teslim ol)' dediğinde, 'Âlemlerin Rabbine teslim oldum' dedi.",
      torahText: "Avram RAB'be iman etti ve RAB bunu ona doğruluk saydı.",
      gospelText: "İbrahim Tanrı'ya iman etti ve kendisine Tanrı'nın dostu dendi.",
    ),
    CrossReferenceTopic(
      id: "cr_3",
      topic: "3. Hz. Musa ve Mukaddes Vadi",
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
    CrossReferenceTopic(
      id: "cr_11",
      topic: "11. Hz. Yunus'un Karanlıklar İçindeki Duası",
      summary: "Balık karnında yükselen tövbe ve ilahi kurtuluş.",
      quranKey: "Enbiyâ 21:87-88",
      torahRef: "Yunus 2:1-2",
      gospelRef: "Matta 12:40",
      quranText: "Karanlıklar içinde: 'Senden başka hiçbir ilah yoktur, Seni tenzih ederim, ben zalimlerden oldum' diye seslendi.",
      torahText: "Yunus balığın karnından Tanrısı RAB'be dua etti: Sıkıntı içindeyken RAB'be yakardım, bana yanıt verdi.",
      gospelText: "Yunus nasıl üç gün üç gece koca balığın karnında kaldıysa...",
    ),
    CrossReferenceTopic(
      id: "cr_12",
      topic: "12. Sadaka ve Gizli İyilik",
      summary: "Gösterişten uzak, yalnızca Allah rızası için yapılan gizli yardımlaşma.",
      quranKey: "Bakara 2:271",
      torahRef: "Özdeyişler 19:17",
      gospelRef: "Matta 6:3-4",
      quranText: "Sadakaları gizleyerek fakirlere verirseniz bu sizin için daha hayırlıdır.",
      torahText: "Yoksula acıyan RAB'be ödünç vermiş olur ve iyiliğinin karşılığını RAB öder.",
      gospelText: "Sadaka verirken sol elin sağ elinin ne yaptığını bilmesin; gizlice gören Baban seni ödüllendirecektir.",
    ),
    CrossReferenceTopic(
      id: "cr_13",
      topic: "13. Kalp Temizliği ve Merhamet",
      summary: "Şekilsel dindarlığın ötesinde arınmış bir kalp (Kalb-i Selim) ve merhamet.",
      quranKey: "Şuarâ 26:88-89",
      torahRef: "Mezmurlar 51:10",
      gospelRef: "Matta 5:7-8",
      quranText: "O gün ne mal fayda verir ne de evlat; ancak Allah'a arınmış bir kalple (kalb-i selîm) gelenler kurtulur.",
      torahText: "Ey Tanrı, içimde temiz bir yürek yarat, içimdeki ruhu yenile.",
      gospelText: "Ne mutlu merhametli olanlara! Ne mutlu yüreği temiz olanlara!",
    ),
    CrossReferenceTopic(
      id: "cr_14",
      topic: "14. Dua ve İlahi Yakınlık",
      summary: "Yaratıcının dua eden kuluna aracısız yakınlığı ve icabeti.",
      quranKey: "Bakara 2:186",
      torahRef: "Mezmurlar 145:18",
      gospelRef: "Matta 7:7",
      quranText: "Kullarım Beni sana soracak olurlarsa, bilsinler ki Ben çok yakınım; bana dua edince dua edenin duasına icabet ederim.",
      torahText: "RAB kendisine yakaran herkese, içtenlikle yakaran herkese yakındır.",
      gospelText: "Dileyin, size verilecek; arayın, bulacaksınız; kapıyı çalın, size açılacaktır.",
    ),
    CrossReferenceTopic(
      id: "cr_15",
      topic: "15. Hesap Günü ve Mutlak Adalet",
      summary: "Zerre kadar iyiliğin ve kötülüğün karşılıksız kalmayacağı büyük hesap günü.",
      quranKey: "Zilzâl 99:7-8",
      torahRef: "Vaiz 12:14",
      gospelRef: "Vahiy 20:12",
      quranText: "Kim zerre ağırlığınca bir hayır işlerse onu görür; kim de zerre ağırlığınca şer işlerse onu görür.",
      torahText: "Çünkü Tanrı, iyi olsun kötü olsun, her gizli işi yargıya getirecektir.",
      gospelText: "Kitaplar açıldı ve herkes kendi yaptıklarına göre yargılandı.",
    ),
  ];

  Future< List< TasbihRecord > > getTasbihRecords() async {
    final db = await database;
    final rows = await db.query('tasbih_records');
    return rows.map(TasbihRecord.fromMap).toList();
  }

  Future< void > updateTasbihCount(int id, int newCount) async {
    final db = await database;
    await db.update(
      'tasbih_records',
      {'count': newCount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future< void > addCustomTasbih(String title, String arabic, int target) async {
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
