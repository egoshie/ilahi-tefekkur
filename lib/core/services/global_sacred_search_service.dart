import 'dart:convert';

import '../models/v42_models.dart';
import 'database_seeder.dart';
import 'offline_sacred_repository.dart';

class GlobalSacredSearchResult {
  final String tradition;
  final String title;
  final String reference;
  final String text;
  final String originalText;
  final int? surahNumber;
  final LiveAyahItem? ayah;
  final BibleVerseItem? bibleVerse;

  const GlobalSacredSearchResult({
    required this.tradition,
    required this.title,
    required this.reference,
    required this.text,
    this.originalText = '',
    this.surahNumber,
    this.ayah,
    this.bibleVerse,
  });
}

class GlobalSacredSearchService {
  final DatabaseService _database;

  GlobalSacredSearchService({DatabaseService? database})
      : _database = database ?? DatabaseService();

  Future<List<GlobalSacredSearchResult>> search(
    String query, {
    bool includeBible = true,
    int limit = 80,
  }) async {
    final term = query.trim();
    if (term.length < 2) return const [];

    final db = await _database.database;
    final results = <GlobalSacredSearchResult>[];
    final seen = <String>{};

    // Sure adları her zaman aranabilir; ayetler yerel önbellekten taranır.
    for (final surah in OfflineSacredRepository.getAllSurahMetadata()) {
      if (TurkishSearchNormalizer.matches(
        '${surah.number} ${surah.nameTurkish}',
        term,
      )) {
        results.add(GlobalSacredSearchResult(
          tradition: "KUR'ÂN",
          title: '${surah.number}. ${surah.nameTurkish}',
          reference: 'Sure',
          text: 'Bu sureyi aç',
          surahNumber: surah.number,
        ));
      }
    }

    try {
      final rows = await db.query('cached_surahs');
      for (final row in rows) {
        try {
          final payload = jsonDecode(row['payload'] as String);
          if (payload is! List) continue;

          for (final raw in payload) {
            final ayah = LiveAyahItem.fromJson(
              Map<String, dynamic>.from(raw as Map),
            );
            final combined = '${ayah.surahName} ${ayah.numberInSurah} '
                '${ayah.turkishText} ${ayah.arabicText}';
            if (!TurkishSearchNormalizer.matches(combined, term)) continue;
            if (!seen.add(ayah.uniqueKey)) continue;

            results.add(GlobalSacredSearchResult(
              tradition: "KUR'ÂN",
              title: '${ayah.surahName} • ${ayah.numberInSurah}. Ayet',
              reference: '${ayah.surahName} ${ayah.numberInSurah}',
              text: ayah.turkishText,
              originalText: ayah.arabicText,
              surahNumber: ayah.surahNumber,
              ayah: ayah,
            ));
          }
        } catch (_) {
          continue;
        }
      }
    } catch (_) {}

    if (includeBible) {
      try {
        final rows = await db.query('cached_bible_chapters');
        for (final row in rows) {
          try {
            final payload = jsonDecode(row['payload'] as String);
            if (payload is! List) continue;

            for (final raw in payload) {
              final map = Map<String, dynamic>.from(raw as Map);
              final verse = BibleVerseItem(
                bookId: int.tryParse(map['bookId'].toString()) ?? 0,
                bookName: (map['bookName'] ?? '').toString(),
                chapter: int.tryParse(map['chapter'].toString()) ?? 1,
                verse: int.tryParse(map['verse'].toString()) ?? 1,
                originalScript: (map['originalScript'] ?? '').toString(),
                turkishText: (map['turkishText'] ?? '').toString(),
              );
              final combined =
                  '${verse.bookName} ${verse.chapter}:${verse.verse} '
                  '${verse.turkishText} ${verse.originalScript}';
              if (!TurkishSearchNormalizer.matches(combined, term)) continue;
              if (!seen.add(verse.uniqueKey)) continue;

              results.add(GlobalSacredSearchResult(
                tradition: 'KİTAP',
                title: '${verse.bookName} • ${verse.chapter}:${verse.verse}',
                reference: '${verse.bookName} ${verse.chapter}:${verse.verse}',
                text: verse.turkishText,
                originalText: verse.originalScript,
                bibleVerse: verse,
              ));
            }
          } catch (_) {
            continue;
          }
        }
      } catch (_) {}
    }

    // Önce metin eşleşmelerini, sonra yalnızca sure adı eşleşmelerini göster.
    results.sort((a, b) {
      final aTitleOnly = a.text == 'Bu sureyi aç';
      final bTitleOnly = b.text == 'Bu sureyi aç';
      return aTitleOnly == bTitleOnly ? 0 : (aTitleOnly ? 1 : -1);
    });

    return results.take(limit).toList(growable: false);
  }
}
