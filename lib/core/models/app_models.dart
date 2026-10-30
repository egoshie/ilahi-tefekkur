class SurahMeta {
  final int number;
  final String nameArabic;
  final String nameTurkish;
  final int ayahCount;
  final String revelationType;

  const SurahMeta({
    required this.number,
    required this.nameArabic,
    required this.nameTurkish,
    required this.ayahCount,
    required this.revelationType,
  });

  factory SurahMeta.fromJson(Map<String, dynamic> json, String trName) {
    return SurahMeta(
      number: json['number'] as int,
      nameArabic: (json['name'] ?? '') as String,
      nameTurkish: trName,
      ayahCount: (json['numberOfAyahs'] ?? 0) as int,
      revelationType: json['revelationType'] == 'Meccan' ? 'Mekki' : 'Medeni',
    );
  }
}

class LiveAyahItem {
  final int globalNumber;
  final int numberInSurah;
  final int surahNumber;
  final String surahName;
  final String arabicText;
  final String turkishText;
  final String audioUrl;

  const LiveAyahItem({
    required this.globalNumber,
    required this.numberInSurah,
    required this.surahNumber,
    required this.surahName,
    required this.arabicText,
    required this.turkishText,
    required this.audioUrl,
  });

  Map<String, dynamic> toJson() => {
        'globalNumber': globalNumber,
        'numberInSurah': numberInSurah,
        'surahNumber': surahNumber,
        'surahName': surahName,
        'arabicText': arabicText,
        'turkishText': turkishText,
        'audioUrl': audioUrl,
      };

  factory LiveAyahItem.fromJson(Map<String, dynamic> map) {
    return LiveAyahItem(
      globalNumber: map['globalNumber'] as int,
      numberInSurah: map['numberInSurah'] as int,
      surahNumber: map['surahNumber'] as int,
      surahName: map['surahName'] as String,
      arabicText: map['arabicText'] as String,
      turkishText: map['turkishText'] as String,
      audioUrl: map['audioUrl'] as String,
    );
  }
}

class BibleBookMeta {
  final int bookId;
  final String testament; // 'torah' (1..39) or 'gospel' (40..66)
  final String nameTurkish;
  final String sefariaName;
  final int totalChapters;

  const BibleBookMeta({
    required this.bookId,
    required this.testament,
    required this.nameTurkish,
    required this.sefariaName,
    required this.totalChapters,
  });
}

class BibleVerseItem {
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String originalScript;
  final String turkishText;

  const BibleVerseItem({
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.originalScript,
    required this.turkishText,
  });
}

class HourlyShortVerse {
  final int index;
  final String ayahKey;
  final String arabicShort;
  final String turkishShort;
  final String reference;

  const HourlyShortVerse({
    required this.index,
    required this.ayahKey,
    required this.arabicShort,
    required this.turkishShort,
    required this.reference,
  });
}

class CrossReferenceTopic {
  final String id;
  final String topic;
  final String summary;
  final String quranKey;
  final String torahRef;
  final String gospelRef;
  final String quranText;
  final String torahText;
  final String gospelText;

  const CrossReferenceTopic({
    required this.id,
    required this.topic,
    required this.summary,
    required this.quranKey,
    required this.torahRef,
    required this.gospelRef,
    required this.quranText,
    required this.torahText,
    required this.gospelText,
  });
}

class EsmaItem {
  final int number;
  final String arabic;
  final String transliteration;
  final String turkishMeaning;
  final int ebcedValue;

  const EsmaItem({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.turkishMeaning,
    required this.ebcedValue,
  });
}

class TasbihRecord {
  final int? id;
  final String title;
  final String arabic;
  final int count;
  final int target;
  final bool isCustom;

  const TasbihRecord({
    this.id,
    required this.title,
    required this.arabic,
    required this.count,
    required this.target,
    this.isCustom = false,
  });

  factory TasbihRecord.fromMap(Map<String, dynamic> map) {
    return TasbihRecord(
      id: map['id'] as int?,
      title: map['title'] as String,
      arabic: map['arabic'] as String,
      count: map['count'] as int,
      target: map['target'] as int,
      isCustom: (map['is_custom'] ?? 0) == 1,
    );
  }
}
