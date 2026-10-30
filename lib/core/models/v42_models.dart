import 'package:flutter/material.dart';

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

  factory SurahMeta.fromJson(Map< String, dynamic > json, String trName) {
    return SurahMeta(
      number: int.tryParse(json['number'].toString()) ?? 1,
      nameArabic: (json['name'] ?? '').toString(),
      nameTurkish: trName,
      ayahCount: int.tryParse(json['numberOfAyahs'].toString()) ?? 0,
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

  String get uniqueKey => 'quran_${surahNumber}_$numberInSurah';

  Map< String, dynamic > toJson() => {
        'globalNumber': globalNumber,
        'numberInSurah': numberInSurah,
        'surahNumber': surahNumber,
        'surahName': surahName,
        'arabicText': arabicText,
        'turkishText': turkishText,
        'audioUrl': audioUrl,
      };

  factory LiveAyahItem.fromJson(Map< String, dynamic > map) {
    return LiveAyahItem(
      globalNumber: int.tryParse(map['globalNumber'].toString()) ?? 1,
      numberInSurah: int.tryParse(map['numberInSurah'].toString()) ?? 1,
      surahNumber: int.tryParse(map['surahNumber'].toString()) ?? 1,
      surahName: (map['surahName'] ?? '').toString(),
      arabicText: (map['arabicText'] ?? '').toString(),
      turkishText: (map['turkishText'] ?? '').toString(),
      audioUrl: (map['audioUrl'] ?? '').toString(),
    );
  }
}

class BibleBookMeta {
  final int bookId;
  final String testament;
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

  String get uniqueKey => 'bible_${bookId}_${chapter}_$verse';
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

class EsmaulHusnaItem {
  final int id;
  final String arabic;
  final String transliteration;
  final String turkishMeaning;
  final int dhikrCount;
  final String reference;

  const EsmaulHusnaItem({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.turkishMeaning,
    required this.dhikrCount,
    required this.reference,
  });

  int get number => id;
  int get ebcedValue => dhikrCount;
}

typedef EsmaItem = EsmaulHusnaItem;

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

  TasbihRecord copyWith({
    int? id,
    String? title,
    String? arabic,
    int? count,
    int? target,
    bool? isCustom,
  }) {
    return TasbihRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      arabic: arabic ?? this.arabic,
      count: count ?? this.count,
      target: target ?? this.target,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  factory TasbihRecord.fromMap(Map< String, dynamic > map) {
    return TasbihRecord(
      id: map['id'] as int?,
      title: (map['title'] ?? '').toString(),
      arabic: (map['arabic'] ?? '').toString(),
      count: int.tryParse(map['count'].toString()) ?? 0,
      target: int.tryParse(map['target'].toString()) ?? 33,
      isCustom: (map['is_custom'] ?? 0) == 1,
    );
  }
}

class StoryThemePreset {
  final String id;
  final String title;
  final Color backgroundColor;
  final Color cardColor;
  final Color accentColor;
  final Color borderColor;

  const StoryThemePreset({
    required this.id,
    required this.title,
    required this.backgroundColor,
    required this.cardColor,
    required this.accentColor,
    required this.borderColor,
  });

  static const List< StoryThemePreset > presets = [
    StoryThemePreset(
      id: 'night_black',
      title: 'Gece Siyahı',
      backgroundColor: Color(0xFF050507),
      cardColor: Color(0xFF101216),
      accentColor: Color(0xFF64FFDA),
      borderColor: Color(0x38FFFFFF),
    ),
    StoryThemePreset(
      id: 'emerald_crystal',
      title: 'Zümrüt Kristal',
      backgroundColor: Color(0xFF041E1B),
      cardColor: Color(0xFF092B27),
      accentColor: Color(0xFF64FFDA),
      borderColor: Color(0x4564FFDA),
    ),
    StoryThemePreset(
      id: 'sapphire_night',
      title: 'Safir Gece',
      backgroundColor: Color(0xFF061326),
      cardColor: Color(0xFF0C1F38),
      accentColor: Color(0xFF80D8FF),
      borderColor: Color(0x4580D8FF),
    ),
    StoryThemePreset(
      id: 'amber_gold',
      title: 'Kehribar Altın',
      backgroundColor: Color(0xFF1F1605),
      cardColor: Color(0xFF2B1F09),
      accentColor: Color(0xFFFFE082),
      borderColor: Color(0x45FFE082),
    ),
  ];
}

class SavedVerseRef {
  final String key;
  final String tradition;
  final String reference;
  final String arabic;
  final String turkish;
  final int savedAtEpochMs;

  const SavedVerseRef({
    required this.key,
    required this.tradition,
    required this.reference,
    required this.arabic,
    required this.turkish,
    required this.savedAtEpochMs,
  });

  Map< String, dynamic > toJson() => {
        'key': key,
        'tradition': tradition,
        'reference': reference,
        'arabic': arabic,
        'turkish': turkish,
        'savedAtEpochMs': savedAtEpochMs,
      };

  factory SavedVerseRef.fromJson(Map< String, dynamic > map) {
    return SavedVerseRef(
      key: (map['key'] ?? '').toString(),
      tradition: (map['tradition'] ?? 'quran').toString(),
      reference: (map['reference'] ?? '').toString(),
      arabic: (map['arabic'] ?? '').toString(),
      turkish: (map['turkish'] ?? '').toString(),
      savedAtEpochMs: int.tryParse(map['savedAtEpochMs'].toString()) ?? 0,
    );
  }
}

class LastReadPosition {
  final String tradition;
  final int bookOrSurahId;
  final String title;
  final int chapterOrAyah;

  const LastReadPosition({
    required this.tradition,
    required this.bookOrSurahId,
    required this.title,
    required this.chapterOrAyah,
  });

  Map< String, dynamic > toJson() => {
        'tradition': tradition,
        'bookOrSurahId': bookOrSurahId,
        'title': title,
        'chapterOrAyah': chapterOrAyah,
      };

  factory LastReadPosition.fromJson(Map< String, dynamic > map) {
    return LastReadPosition(
      tradition: (map['tradition'] ?? 'quran').toString(),
      bookOrSurahId: int.tryParse(map['bookOrSurahId'].toString()) ?? 1,
      title: (map['title'] ?? 'Fâtiha Sûresi').toString(),
      chapterOrAyah: int.tryParse(map['chapterOrAyah'].toString()) ?? 1,
    );
  }
}

class UserProgressState {
  static const int currentSchemaVersion = 42;

  final int schemaVersion;
  final LastReadPosition? lastRead;
  final List< SavedVerseRef > favorites;
  final List< SavedVerseRef > bookmarks;
  final int dailyDhikrCount;
  final int missedPrayers;
  final int initialPrayers;
  final int dailyPrayerPace;
  final int missedFasts;
  final Set< int > completedJuzs;

  const UserProgressState({
    this.schemaVersion = currentSchemaVersion,
    this.lastRead,
    this.favorites = const [],
    this.bookmarks = const [],
    this.dailyDhikrCount = 0,
    this.missedPrayers = 18,
    this.initialPrayers = 60,
    this.dailyPrayerPace = 2,
    this.missedFasts = 4,
    this.completedJuzs = const {},
  });

  bool isFavorite(String key) => favorites.any((e) => e.key == key);
  bool isBookmarked(String key) => bookmarks.any((e) => e.key == key);

  UserProgressState copyWith({
    int? schemaVersion,
    LastReadPosition? lastRead,
    List< SavedVerseRef >? favorites,
    List< SavedVerseRef >? bookmarks,
    int? dailyDhikrCount,
    int? missedPrayers,
    int? initialPrayers,
    int? dailyPrayerPace,
    int? missedFasts,
    Set< int >? completedJuzs,
  }) {
    return UserProgressState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      lastRead: lastRead ?? this.lastRead,
      favorites: favorites ?? this.favorites,
      bookmarks: bookmarks ?? this.bookmarks,
      dailyDhikrCount: dailyDhikrCount ?? this.dailyDhikrCount,
      missedPrayers: missedPrayers ?? this.missedPrayers,
      initialPrayers: initialPrayers ?? this.initialPrayers,
      dailyPrayerPace: dailyPrayerPace ?? this.dailyPrayerPace,
      missedFasts: missedFasts ?? this.missedFasts,
      completedJuzs: completedJuzs ?? this.completedJuzs,
    );
  }
}
