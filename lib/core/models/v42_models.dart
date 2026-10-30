import 'package:flutter/foundation.dart';

@immutable
class V42SurahMeta {
  final int number;
  final String nameArabic;
  final String nameTurkish;
  final int ayahCount;
  final String revelation;
  const V42SurahMeta({required this.number, required this.nameArabic, required this.nameTurkish, required this.ayahCount, required this.revelation});
}

@immutable
class V42BibleBookMeta {
  final int bookId;
  final String nameTurkish;
  final String testament;
  final int totalChapters;
  const V42BibleBookMeta({required this.bookId, required this.nameTurkish, required this.testament, required this.totalChapters});
}

@immutable
class EsmaItem {
  final int number;
  final String arabic;
  final String transliteration;
  final String meaning;
  const EsmaItem({required this.number, required this.arabic, required this.transliteration, required this.meaning});

  int get abjadValue {
    const values = <String, int>{
      'ا': 1, 'أ': 1, 'إ': 1, 'آ': 1, 'ٱ': 1,
      'ب': 2, 'ج': 3, 'د': 4, 'ه': 5, 'ة': 5, 'و': 6, 'ؤ': 6,
      'ز': 7, 'ح': 8, 'ط': 9, 'ي': 10, 'ى': 10, 'ئ': 10,
      'ك': 20, 'ل': 30, 'م': 40, 'ن': 50, 'س': 60, 'ع': 70,
      'ف': 80, 'ص': 90, 'ق': 100, 'ر': 200, 'ش': 300, 'ت': 400,
      'ث': 500, 'خ': 600, 'ذ': 700, 'ض': 800, 'ظ': 900, 'غ': 1000,
    };
    var total = 0;
    for (final rune in arabic.runes) {
      total += values[String.fromCharCode(rune)] ?? 0;
    }
    return total;
  }
}

@immutable
class V42Verse {
  final String bookId;
  final int chapter;
  final int verse;
  final String originalScript;
  final String turkishText;
  const V42Verse({required this.bookId, required this.chapter, required this.verse, this.originalScript = '', required this.turkishText});

  factory V42Verse.fromJson(Map<String, dynamic> json) => V42Verse(
    bookId: (json['bookId'] ?? json['surah'] ?? '').toString(),
    chapter: (json['chapter'] as num?)?.toInt() ?? (json['surah'] as num?)?.toInt() ?? 0,
    verse: (json['verse'] as num?)?.toInt() ?? (json['ayah'] as num?)?.toInt() ?? 0,
    originalScript: (json['originalScript'] ?? json['arabic'] ?? '').toString(),
    turkishText: (json['turkishText'] ?? json['translation'] ?? '').toString(),
  );
}

@immutable
class V42HourlyVerse {
  String get arabic => arabicShort;
  String get turkish => turkishShort;
  final String arabicShort;
  final String turkishShort;
  final String reference;
  const V42HourlyVerse({required this.arabicShort, required this.turkishShort, required this.reference});
}
