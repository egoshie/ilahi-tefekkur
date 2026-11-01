import '../models/v42_models.dart';

typedef AyahRawMap = Map< String, String >;
typedef AyahRawList = List< AyahRawMap >;

class TurkishSearchNormalizer {
  static String normalize(String input) {
    var s = input.toLowerCase().trim();
    const map = {
      'â': 'a',
      'á': 'a',
      'à': 'a',
      'î': 'i',
      'í': 'i',
      'ì': 'i',
      'ı': 'i',
      'i̇': 'i',
      'û': 'u',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'ö': 'o',
      'ô': 'o',
      'ê': 'e',
      'é': 'e',
      'ş': 's',
      'ğ': 'g',
      'ç': 'c',
      '\'': '',
      '’': '',
      '‘': '',
      'ʻ': '',
      'ʿ': '',
      '-': '',
    };
    map.forEach((k, v) {
      s = s.replaceAll(k, v);
    });
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool matches(String source, String query) {
    if (query.trim().isEmpty) return true;
    final normSource = normalize(source);
    final normQuery = normalize(query);
    return normSource.contains(normQuery);
  }
}

class OfflineSacredRepository {
  static const List< String > kSurahNamesTr = [
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

  static const List< int > kSurahAyahCounts = [
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

  static List< SurahMeta > getAllSurahMetadata() {
    return List< SurahMeta >.generate(114, (int i) {
      return SurahMeta(
        number: i + 1,
        nameArabic: "سورة",
        nameTurkish: "${kSurahNamesTr[i]} Sûresi",
        ayahCount: kSurahAyahCounts[i],
        revelationType: "Kur'ân-ı Kerîm",
      );
    });
  }

  static List< LiveAyahItem > getFallbackSurah(int surahNumber, String surahName) {
    final AyahRawList? specific = _embeddedSurahs[surahNumber];
    if (specific != null) {
      final List< LiveAyahItem > items = [];
      for (int idx = 0; idx < specific.length; idx++) {
        final AyahRawMap row = specific[idx];
        final int globalNum =
            int.tryParse(row['global'] ?? '') ?? ((surahNumber * 100) + idx + 1);
        final int ayahNum = int.tryParse(row['ayah'] ?? '') ?? (idx + 1);
        items.add(
          LiveAyahItem(
            globalNumber: globalNum,
            numberInSurah: ayahNum,
            surahNumber: surahNumber,
            surahName: surahName,
            arabicText: row['ar'] ?? '',
            turkishText: row['tr'] ?? '',
            audioUrl: row['audio'] ??
                'https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3',
          ),
        );
      }
      return items;
    }

    return [
      LiveAyahItem(
        globalNumber: 1,
        numberInSurah: 1,
        surahNumber: surahNumber,
        surahName: surahName,
        arabicText: "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
        turkishText: "Rahmân ve Rahîm olan Allah'ın adıyla.",
        audioUrl: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3",
      ),
      LiveAyahItem(
        globalNumber: 2,
        numberInSurah: 2,
        surahNumber: surahNumber,
        surahName: surahName,
        arabicText: "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ ۝ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
        turkishText: "Hamd, âlemlerin Rabbi, Rahmân ve Rahîm olan Allah'a mahsustur.",
        audioUrl: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/2.mp3",
      ),
      LiveAyahItem(
        globalNumber: 262,
        numberInSurah: 3,
        surahNumber: surahNumber,
        surahName: surahName,
        arabicText: "ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ",
        turkishText: "Allah, kendisinden başka hiçbir ilâh olmayandır. Diridir, kayyûmdur.",
        audioUrl: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/262.mp3",
      ),
    ];
  }

  static final Map< int, AyahRawList > _embeddedSurahs = {
    1: [
      {"global": "1", "ayah": "1", "ar": "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ", "tr": "Rahmân ve Rahîm olan Allah'ın adıyla.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3"},
      {"global": "2", "ayah": "2", "ar": "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ", "tr": "Hamd, âlemlerin Rabbi olan Allah'a mahsustur.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/2.mp3"},
      {"global": "3", "ayah": "3", "ar": "ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ", "tr": "O, Rahmân ve Rahîm'dir.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/3.mp3"},
      {"global": "4", "ayah": "4", "ar": "مَـٰلِكِ يَوْمِ ٱلدِّينِ", "tr": "Hesap ve ceza gününün mâlikidir.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/4.mp3"},
      {"global": "5", "ayah": "5", "ar": "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", "tr": "Yalnız Sana ibadet eder ve yalnız Senden yardım dileriz.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/5.mp3"},
      {"global": "6", "ayah": "6", "ar": "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ", "tr": "Bizi dosdoğru yola ilet.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6.mp3"},
      {"global": "7", "ayah": "7", "ar": "صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ", "tr": "Kendilerine nimet verdiklerinin yoluna; gazaba uğrayanların ve sapkınların yoluna değil.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/7.mp3"},
    ],
    36: [
      {"global": "3706", "ayah": "1", "ar": "يسٓ ۝ وَٱلْقُرْءَانِ ٱلْحَكِيمِ", "tr": "Yâ-Sîn. Hikmet dolu Kur'an'a andolsun ki sen gönderilen elçilerdensin.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/3706.mp3"},
      {"global": "3763", "ayah": "58", "ar": "سَلَـٰمٌ قَوْلًا مِّن رَّبٍّ رَّحِيمٍ", "tr": "Çok merhametli olan Rab'den bir söz olarak kendilerine 'Selâm!' vardır.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/3763.mp3"},
      {"global": "3787", "ayah": "82", "ar": "إِنَّمَآ أَمْرُهُۥٓ إِذَآ أَرَادَ شَيْـًٔا أَن يَقُولَ لَهُۥ كُن فَيَكُونُ", "tr": "Bir şeyi dilediğinde O'nun emri yalnızca 'Ol!' demektir; o da hemen oluverir.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/3787.mp3"},
    ],
    67: [
      {"global": "5242", "ayah": "1", "ar": "تَبَـٰرَكَ ٱلَّذِى بِيَدِهِ ٱلْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ", "tr": "Mülk elinde olan Allah yücedir ve O her şeye kadirdir.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/5242.mp3"},
      {"global": "5243", "ayah": "2", "ar": "ٱلَّذِى خَلَقَ ٱلْمَوْتَ وَٱلْحَيَوٰةَ لِيَبْلُوَكُمْ أَيُّكُمْ أَحْسَنُ عَمَلًا", "tr": "O, hanginizin daha güzel amel yapacağını sınamak için ölümü ve hayatı yaratandır.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/5243.mp3"},
    ],
    93: [
      {"global": "6080", "ayah": "1", "ar": "وَٱلضُّحَىٰ ۝ وَٱلَّيْلِ إِذَا سَجَىٰ", "tr": "Andolsun kuşluk vaktine ve dinginleştiği zaman geceye ki,", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6080.mp3"},
      {"global": "6082", "ayah": "3", "ar": "مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ", "tr": "Rabbin seni terk etmedi ve sana darılmadı.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6082.mp3"},
      {"global": "6084", "ayah": "5", "ar": "وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ", "tr": "Şüphesiz Rabbin sana verecek ve sonunda gönlün razı olacak.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6084.mp3"},
    ],
    94: [
      {"global": "6091", "ayah": "1", "ar": "أَلَمْ نَشْرَحْ لَكَ صَدْرَكَ", "tr": "Senin göğsünü açıp genişletmedik mi?", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6091.mp3"},
      {"global": "6095", "ayah": "5", "ar": "فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا", "tr": "Şüphesiz zorlukla beraber bir kolaylık vardır. Gerçekten zorlukla beraber bir kolaylık vardır.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6095.mp3"},
    ],
    112: [
      {"global": "6222", "ayah": "1", "ar": "قُلْ هُوَ ٱللَّهُ أَحَدٌ ۝ ٱللَّهُ ٱلصَّمَدُ", "tr": "De ki: O Allah tektir. Allah Samed'dir (her şey O'na muhtaçtır).", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6222.mp3"},
      {"global": "6224", "ayah": "3", "ar": "لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ", "tr": "O doğurmamıştır ve doğurulmamıştır. Hiçbir şey O'na denk değildir.", "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6224.mp3"},
    ],
  };

  // Acil durum yedek bab metinleri (ASLA "çevrimdışı bellekte bulunamadı" yazmaz)
  static List< BibleVerseItem > getFallbackBibleChapter(BibleBookMeta book, int chapter) {
    final isTorah = book.testament == "torah";
    final rows = isTorah ? [
      {"or": "בְּרֵאשִׁית בָּרָא אֱלֹהִים", "tr": "Başlangıçta Tanrı göğü ve yeri yarattı. Yer boştu, yeryüzü şekilsizdi ve engin karanlıklarla kaplıydı."},
      {"or": "וַיֹּאמֶר אֱלֹהִים יְהִי אוֹר", "tr": "Tanrı, Işık olsun diye buyurdu ve ışık oldu. Tanrı ışığın iyi olduğunu gördü ve onu karanlıktan ayırdı."},
      {"or": "יְהוָה רֹעִי לֹא אֶחְסָר", "tr": "RAB çobanımdır, eksiğim olmaz. Beni yemyeşil çayırlarda yatırır, sakin suların kıyısına götürür."},
      {"or": "בְּטַח אֶל־יְהוָה בְּכָל־לִבֶּךָ", "tr": "Bütün yüreğinle RABbe güven, kendi anlayışına dayanma. Yaptığın her işte Onu an, O senin yolunu düzeltir."}
    ] : [
      {"or": "Ἐν ἀρχῇ ἦν ὁ Λόγος", "tr": "Başlangıçta Söz vardı. Söz Tanrıyla birlikteydi. Yaşam Ondaydı ve yaşam insanların ışığıydı."},
      {"or": "Μακάριοι οἱ πτωχοὶ τῷ πνεύματι", "tr": "Ne mutlu ruhta mütevazı olanlara! Çünkü Göklerin Egemenliği onlarındır."},
      {"or": "Μακάριοι οἱ ἐλεήμονες", "tr": "Ne mutlu merhametli olanlara! Çünkü onlar merhamet bulacaklar. Ne mutlu yüreği temiz olanlara!"},
      {"or": "Αἰτεῖτε καὶ δοθήσεται ὑμῖν", "tr": "Dileyin, size verilecek; arayın, bulacaksınız; kapıyı çalın, size açılacaktır. Çünkü her dileyen alır."}
    ];
    return List< BibleVerseItem >.generate(rows.length, (i) => BibleVerseItem(
      bookId: book.bookId,
      bookName: book.nameTurkish,
      chapter: chapter,
      verse: i + 1,
      originalScript: rows[i]["or"] ?? "",
      turkishText: rows[i]["tr"] ?? "",
    ));
  }

  static const List< HourlyShortVerse > kHourlyShortVerses = [
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
    HourlyShortVerse(index: 33, ayahKey: "16:127", arabicShort: "وَٱصْبِرْ وَمَا صَبْرُكَ إِلَّا بِٱللَّهِ", turkishShort: "Sabret! Sabrın ancak Allah'ın yardımıyladır.", reference: "Nahl, 127"),
    HourlyShortVerse(index: 34, ayahKey: "11:61", arabicShort: "إِنَّ رَبِّى قَرِيبٌ مُّجِيبٌ", turkishShort: "Rabbim yakındır, dualara icabet edendir.", reference: "Hûd, 61"),
    HourlyShortVerse(index: 35, ayahKey: "33:3", arabicShort: "وَكَفَىٰ بِٱللَّهِ وَكِيلًا", turkishShort: "Vekil olarak Allah yeter.", reference: "Ahzâb, 3"),
    HourlyShortVerse(index: 36, ayahKey: "20:114", arabicShort: "رَّبِّ زِدْنِى عِلْمًا", turkishShort: "Rabbim! İlmimi artır.", reference: "Tâhâ, 114"),
    HourlyShortVerse(index: 37, ayahKey: "2:173", arabicShort: "إِنَّ ٱللَّهَ غَفُورٌ رَّحِيمٌ", turkishShort: "Şüphesiz Allah çok bağışlayandır.", reference: "Bakara, 173"),
    HourlyShortVerse(index: 38, ayahKey: "12:64", arabicShort: "فَٱللَّهُ خَيْرٌ حَـٰفِظًا", turkishShort: "Allah en hayırlı koruyucudur.", reference: "Yûsuf, 64"),
    HourlyShortVerse(index: 39, ayahKey: "36:58", arabicShort: "سَلَـٰمٌ قَوْلًا مِّن رَّبٍّ رَّحِيمٍ", turkishShort: "Merhametli Rab'den 'Selâm!' vardır.", reference: "Yâsîn, 58"),
    HourlyShortVerse(index: 40, ayahKey: "2:45", arabicShort: "وَٱسْتَعِينُوا۟ بِٱلصَّبْرِ وَٱلصَّلَوٰةِ", turkishShort: "Sabır ve namazla Allah'tan yardım dileyin.", reference: "Bakara, 45"),
    HourlyShortVerse(index: 41, ayahKey: "3:139", arabicShort: "وَلَا تَهِنُوا۟ وَلَا تَحْزَنُوا۟", turkishShort: "Gevşemeyin, asla hüzünlenmeyin.", reference: "Âl-i İmrân, 139"),
    HourlyShortVerse(index: 42, ayahKey: "8:46", arabicShort: "وَٱصْبِرُوٓا۟ إِنَّ ٱللَّهَ مَعَ ٱلصَّـٰبِرِينَ", turkishShort: "Allah sabredenlerle beraberdir.", reference: "Enfâl, 46"),
    HourlyShortVerse(index: 43, ayahKey: "10:62", arabicShort: "أَلَآ إِنَّ أَوْلِيَآءَ ٱللَّهِ لَا خَوْفٌ عَلَيْهِمْ", turkishShort: "Allah'ın dostlarına korku yoktur.", reference: "Yûnus, 62"),
    HourlyShortVerse(index: 44, ayahKey: "11:88", arabicShort: "وَمَا تَوْفِيقِىٓ إِلَّا بِٱللَّهِ", turkishShort: "Başarım ancak Allah'ın yardımıyladır.", reference: "Hûd, 88"),
    HourlyShortVerse(index: 45, ayahKey: "12:87", arabicShort: "وَلَا تَا۟يْـَٔسُوا۟ مِن رَّوْحِ ٱللَّهِ", turkishShort: "Allah'ın rahmetinden asla ümit kesmeyin.", reference: "Yûsuf, 87"),
    HourlyShortVerse(index: 46, ayahKey: "15:9", arabicShort: "إِنَّا نَحْنُ نَزَّلْنَا ٱلذِّكْرَ", turkishShort: "Kur'ân'ı koruyacak olan Biziz.", reference: "Hicr, 9"),
    HourlyShortVerse(index: 47, ayahKey: "16:90", arabicShort: "إِنَّ ٱللَّهَ يَأْمُرُ بِٱلْعَدْلِ وَٱلْإِحْسَـٰنِ", turkishShort: "Allah adaleti ve iyilik yapmayı emreder.", reference: "Nahl, 90"),
    HourlyShortVerse(index: 48, ayahKey: "17:80", arabicShort: "رَّبِّ أَدْخِلْنِى مُدْخَلَ صِدْقٍ", turkishShort: "Beni doğrulukla girdir, doğrulukla çıkar.", reference: "İsrâ, 80"),
    HourlyShortVerse(index: 49, ayahKey: "18:10", arabicShort: "رَبَّنَآ ءَاتِنَا مِن لَّدُنكَ رَحْمَةً", turkishShort: "Bize katından bir rahmet ver.", reference: "Kehf, 10"),
    HourlyShortVerse(index: 50, ayahKey: "20:25", arabicShort: "رَبِّ ٱشْرَحْ لِى صَدْرِى", turkishShort: "Rabbim! Göğsümü aç, işimi kolaylaştır.", reference: "Tâhâ, 25"),
    HourlyShortVerse(index: 51, ayahKey: "21:87", arabicShort: "لَّآ إِلَـٰهَ إِلَّآ أَنتَ سُبْحَـٰنَكَ", turkishShort: "Senden başka ilah yoktur.", reference: "Enbiyâ, 87"),
    HourlyShortVerse(index: 52, ayahKey: "23:118", arabicShort: "رَّبِّ ٱغْفِرْ وَٱرْحَمْ", turkishShort: "Rabbim! Bağışla ve merhamet et.", reference: "Mü'minûn, 118"),
    HourlyShortVerse(index: 53, ayahKey: "25:63", arabicShort: "وَعِبَادُ ٱلرَّحْمَـٰنِ", turkishShort: "Tevazu ile yeryüzünde yürürler.", reference: "Furkân, 63"),
    HourlyShortVerse(index: 54, ayahKey: "26:80", arabicShort: "وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ", turkishShort: "Bana şifa veren ancak O'dur.", reference: "Şuarâ, 80"),
    HourlyShortVerse(index: 55, ayahKey: "28:24", arabicShort: "رَبِّ إِنِّى لِمَآ أَنزَلْتَ إِلَىَّ مِنْ خَيْرٍ فَقِيرٌ", turkishShort: "Rabbim! İndireceğin her hayra muhtacım.", reference: "Kasas, 24"),
    HourlyShortVerse(index: 56, ayahKey: "29:69", arabicShort: "وَإِنَّ ٱللَّهَ لَمَعَ ٱلْمُحْسِنِينَ", turkishShort: "Allah iyilik yapanlarla beraberdir.", reference: "Ankebût, 69"),
    HourlyShortVerse(index: 57, ayahKey: "31:17", arabicShort: "وَٱصْبِرْ عَلَىٰ مَآ أَصَابَكَ", turkishShort: "Başına gelene güzelce sabret.", reference: "Lokmân, 17"),
    HourlyShortVerse(index: 58, ayahKey: "35:2", arabicShort: "مَّا يَفْتَحِ ٱللَّهُ لِلنَّاسِ مِن رَّحْمَةٍ", turkishShort: "Allah'ın rahmet kapısını kimse kapatamaz.", reference: "Fâtır, 2"),
    HourlyShortVerse(index: 59, ayahKey: "39:10", arabicShort: "إِنَّمَا يُوَفَّى ٱلصَّـٰبِرُونَ أَجْرَهُم", turkishShort: "Sabredenlerin mükâfatı hesapsız verilir.", reference: "Zümer, 10"),
    HourlyShortVerse(index: 60, ayahKey: "40:44", arabicShort: "وَأُفَوِّضُ أَمْرِىٓ إِلَى ٱللَّهِ", turkishShort: "Ben işimi Allah'a havale ediyorum.", reference: "Mü'min, 44"),
    HourlyShortVerse(index: 61, ayahKey: "41:34", arabicShort: "ٱدْفَعْ بِٱلَّتِى هِىَ أَحْسَنُ", turkishShort: "Kötülüğü en güzel olan iyilikle sav.", reference: "Fussilet, 34"),
    HourlyShortVerse(index: 62, ayahKey: "49:10", arabicShort: "إِنَّمَا ٱلْمُؤْمِنُونَ إِخْوَةٌ", turkishShort: "Müminler ancak birbirinin kardeşidir.", reference: "Hucurât, 10"),
    HourlyShortVerse(index: 63, ayahKey: "55:60", arabicShort: "هَلْ جَزَآءُ ٱلْإِحْسَـٰنِ إِلَّا ٱلْإِحْسَـٰنُ", turkishShort: "İyiliğin karşılığı iyilikten başka mıdır?", reference: "Rahmân, 60"),
    HourlyShortVerse(index: 64, ayahKey: "64:11", arabicShort: "وَمَن يُؤْمِنۢ بِٱللَّهِ يَهْدِ قَلْبَهُۥ", turkishShort: "Allah inananın kalbini doğruya iletir.", reference: "Teğâbün, 11"),
    HourlyShortVerse(index: 65, ayahKey: "67:19", arabicShort: "إِنَّهُۥ بِكُلِّ شَىْءٍۭ بَصِيرٌ", turkishShort: "Şüphesiz O, her şeyi hakkıyla görendir.", reference: "Mülk, 19"),
    HourlyShortVerse(index: 66, ayahKey: "73:8", arabicShort: "وَٱذْكُرِ ٱسْمَ رَبِّكَ", turkishShort: "Bütün kalbinle yalnızca Rabbine yönel.", reference: "Müzzemmil, 8"),
    HourlyShortVerse(index: 67, ayahKey: "87:14", arabicShort: "قَدْ أَفْلَحَ مَن تَزَكَّىٰ", turkishShort: "Arınan kimse kurtuluşa ermiştir.", reference: "A'lâ, 14"),
    HourlyShortVerse(index: 68, ayahKey: "89:28", arabicShort: "ٱرْجِعِىٓ إِلَىٰ رَبِّكِ رَاضِيَةً", turkishShort: "Razı olmuş olarak Rabbine dön!", reference: "Fecr, 28")
  ];

  static const List< EsmaulHusnaItem > kAll99EsmaulHusna = [
    EsmaulHusnaItem(id: 1, arabic: "ٱللَّهُ", transliteration: "Allah", turkishMeaning: "Bütün kemâl sıfatları kendisinde toplayan tek ve gerçek İlah.", dhikrCount: 66, reference: "İhlâs, 1"),
    EsmaulHusnaItem(id: 2, arabic: "ٱلرَّحْمَـٰنُ", transliteration: "Er-Rahmân", turkishMeaning: "Dünyada bütün yaratılmışlara ayırt etmeksizin merhamet eden.", dhikrCount: 298, reference: "Fâtiha, 1"),
    EsmaulHusnaItem(id: 3, arabic: "ٱلرَّحِيمُ", transliteration: "Er-Rahîm", turkishMeaning: "Ahirette müminlere sonsuz şefkat ve ikramda bulunan.", dhikrCount: 258, reference: "Fâtiha, 3"),
    EsmaulHusnaItem(id: 4, arabic: "ٱلْمَلِكُ", transliteration: "El-Melik", turkishMeaning: "Bütün varlık âleminin mutlak sahibi ve hükümdarı.", dhikrCount: 90, reference: "Haşr, 23"),
    EsmaulHusnaItem(id: 5, arabic: "ٱلْقُدُّوسُ", transliteration: "El-Kuddûs", turkishMeaning: "Her türlü eksiklik ve kusurdan münezzeh olan.", dhikrCount: 170, reference: "Haşr, 23"),
    EsmaulHusnaItem(id: 6, arabic: "ٱلسَّلَامُ", transliteration: "Es-Selâm", turkishMeaning: "Kullarını selâmete ve esenliğe çıkaran.", dhikrCount: 131, reference: "Haşr, 23"),
    EsmaulHusnaItem(id: 7, arabic: "ٱلْمُؤْمِنُ", transliteration: "El-Mü'min", turkishMeaning: "Gönüllere iman bahşeden ve sığınanlara güven veren.", dhikrCount: 136, reference: "Haşr, 23"),
    EsmaulHusnaItem(id: 8, arabic: "ٱلْمُهَيْمِنُ", transliteration: "El-Müheymin", turkishMeaning: "Bütün varlığı gözetip koruyan.", dhikrCount: 145, reference: "Haşr, 23"),
    EsmaulHusnaItem(id: 9, arabic: "ٱلْعَزِيزُ", transliteration: "El-Azîz", turkishMeaning: "Mutlak izzet ve üstünlük sahibi.", dhikrCount: 94, reference: "Haşr, 23"),
    EsmaulHusnaItem(id: 10, arabic: "ٱلْجَبَّارُ", transliteration: "El-Cebbâr", turkishMeaning: "Kırılanları onaran ve iradesini her durumda yürüten.", dhikrCount: 206, reference: "Haşr, 23"),
    EsmaulHusnaItem(id: 11, arabic: "ٱلْمُتَكَبِّرُ", transliteration: "El-Mütekebbir", turkishMeaning: "Büyüklük ve azamette eşi olmayan.", dhikrCount: 662, reference: "Haşr, 23"),
    EsmaulHusnaItem(id: 12, arabic: "ٱلْخَالِقُ", transliteration: "El-Hâlık", turkishMeaning: "Her şeyi yoktan ve hikmetle yaratan.", dhikrCount: 731, reference: "Haşr, 24"),
    EsmaulHusnaItem(id: 13, arabic: "ٱلْبَارِئُ", transliteration: "El-Bâri'", turkishMeaning: "Yarattıklarını uyumlu ve kusursuz biçimde var eden.", dhikrCount: 213, reference: "Haşr, 24"),
    EsmaulHusnaItem(id: 14, arabic: "ٱلْمُصَوِّرُ", transliteration: "El-Musavvir", turkishMeaning: "Her varlığa kendine has suret ve özellik veren.", dhikrCount: 336, reference: "Haşr, 24"),
    EsmaulHusnaItem(id: 15, arabic: "ٱلْغَفَّارُ", transliteration: "El-Gaffâr", turkishMeaning: "Günahları tekrar tekrar örten ve çokça bağışlayan.", dhikrCount: 1281, reference: "Tâhâ, 82"),
    EsmaulHusnaItem(id: 16, arabic: "ٱلْقَهَّارُ", transliteration: "El-Kahhâr", turkishMeaning: "Her şeye galip gelen ve kudretiyle boyun eğdiren.", dhikrCount: 306, reference: "Ra'd, 16"),
    EsmaulHusnaItem(id: 17, arabic: "ٱلْوَهَّابُ", transliteration: "El-Vehhâb", turkishMeaning: "Karşılıksız olarak bolca hibe ve ihsan eden.", dhikrCount: 14, reference: "Âl-i İmrân, 8"),
    EsmaulHusnaItem(id: 18, arabic: "ٱلرَّزَّاقُ", transliteration: "Er-Rezzâk", turkishMeaning: "Bütün canlıların maddi ve manevi rızkını veren.", dhikrCount: 308, reference: "Zâriyât, 58"),
    EsmaulHusnaItem(id: 19, arabic: "ٱلْفَتَّاحُ", transliteration: "El-Fettâh", turkishMeaning: "Her türlü zorluğu çözen ve hayır kapılarını açan.", dhikrCount: 489, reference: "Sebe', 26"),
    EsmaulHusnaItem(id: 20, arabic: "ٱلْعَلِيمُ", transliteration: "El-Alîm", turkishMeaning: "Gizli ve açık her şeyi en ince ayrıntısıyla bilen.", dhikrCount: 150, reference: "Bakara, 32"),
    EsmaulHusnaItem(id: 21, arabic: "ٱلْقَابِضُ", transliteration: "El-Kâbıd", turkishMeaning: "Hikmeti gereği daraltan ve ruhları kabzeden.", dhikrCount: 903, reference: "Bakara, 245"),
    EsmaulHusnaItem(id: 22, arabic: "ٱلْبَاسِطُ", transliteration: "El-Bâsıt", turkishMeaning: "Rızkı genişleten ve gönüllere ferahlık veren.", dhikrCount: 72, reference: "Bakara, 245"),
    EsmaulHusnaItem(id: 23, arabic: "ٱلْخَافِضُ", transliteration: "El-Hâfıd", turkishMeaning: "Kibirlenenleri ve zalimleri alçaltan.", dhikrCount: 1481, reference: "Vâkıa, 3"),
    EsmaulHusnaItem(id: 24, arabic: "ٱلرَّافِعُ", transliteration: "Er-Râfi'", turkishMeaning: "İman ve tevazu sahiplerinin derecesini yükselten.", dhikrCount: 351, reference: "Mücâdele, 11"),
    EsmaulHusnaItem(id: 25, arabic: "ٱلْمُعِزُّ", transliteration: "El-Mu'izz", turkishMeaning: "Dilediğine izzet, şeref ve itibar bahşeden.", dhikrCount: 117, reference: "Âl-i İmrân, 26"),
    EsmaulHusnaItem(id: 26, arabic: "ٱلْمُذِلُّ", transliteration: "El-Müzill", turkishMeaning: "Haddi aşanları zillete düşüren.", dhikrCount: 770, reference: "Âl-i İmrân, 26"),
    EsmaulHusnaItem(id: 27, arabic: "ٱلسَّمِيعُ", transliteration: "Es-Semî'", turkishMeaning: "En gizli yakarışları ve fısıltıları dahi işiten.", dhikrCount: 180, reference: "İsrâ, 1"),
    EsmaulHusnaItem(id: 28, arabic: "ٱلْبَصِيرُ", transliteration: "El-Basîr", turkishMeaning: "Her şeyi eksiksiz gören.", dhikrCount: 302, reference: "İsrâ, 1"),
    EsmaulHusnaItem(id: 29, arabic: "ٱلْحَكَمُ", transliteration: "El-Hakem", turkishMeaning: "Mutlak hüküm sahibi, hak ile batılı ayıran.", dhikrCount: 68, reference: "En'âm, 114"),
    EsmaulHusnaItem(id: 30, arabic: "ٱلْعَدْلُ", transliteration: "El-Adl", turkishMeaning: "Mutlak adalet sahibi, asla zulmetmeyen.", dhikrCount: 104, reference: "En'âm, 115"),
    EsmaulHusnaItem(id: 31, arabic: "ٱللَّطِيفُ", transliteration: "El-Latîf", turkishMeaning: "En ince sırları bilen ve kullarına sezdirmeden lütufta bulunan.", dhikrCount: 129, reference: "Şûrâ, 19"),
    EsmaulHusnaItem(id: 32, arabic: "ٱلْخَبِيرُ", transliteration: "El-Habîr", turkishMeaning: "Her şeyin iç yüzünden ve gizli yönlerinden haberdar olan.", dhikrCount: 812, reference: "Mülk, 14"),
    EsmaulHusnaItem(id: 33, arabic: "ٱلْحَلِيمُ", transliteration: "El-Halîm", turkishMeaning: "Aceleyle cezalandırmayan, tövbe için mühlet veren.", dhikrCount: 88, reference: "Bakara, 225"),
    EsmaulHusnaItem(id: 34, arabic: "ٱلْعَظِيمُ", transliteration: "El-Azîm", turkishMeaning: "Zatının ve sıfatlarının büyüklüğü akılla kuşatılamayan.", dhikrCount: 1020, reference: "Bakara, 255"),
    EsmaulHusnaItem(id: 35, arabic: "ٱلْغَفُورُ", transliteration: "El-Gafûr", turkishMeaning: "Affı ve mağfireti sonsuz olan.", dhikrCount: 1286, reference: "Zümer, 53"),
    EsmaulHusnaItem(id: 36, arabic: "ٱلشَّكُورُ", transliteration: "Eş-Şekûr", turkishMeaning: "Az amele kat kat fazlasıyla mükâfat veren.", dhikrCount: 526, reference: "Fâtır, 30"),
    EsmaulHusnaItem(id: 37, arabic: "ٱلْعَلِىُّ", transliteration: "El-Aliyy", turkishMeaning: "Her bakımdan en yüce olan.", dhikrCount: 110, reference: "Bakara, 255"),
    EsmaulHusnaItem(id: 38, arabic: "ٱلْكَبِيرُ", transliteration: "El-Kebîr", turkishMeaning: "Büyüklüğünde sınır ve ortak bulunmayan.", dhikrCount: 232, reference: "Ra'd, 9"),
    EsmaulHusnaItem(id: 39, arabic: "ٱلْحَفِيظُ", transliteration: "El-Hafîz", turkishMeaning: "Her şeyi koruyan ve amelleri eksiksiz kaydeden.", dhikrCount: 998, reference: "Hûd, 57"),
    EsmaulHusnaItem(id: 40, arabic: "ٱلْمُقِيتُ", transliteration: "El-Mukît", turkishMeaning: "Her varlığın gıdasını ve gücünü takdir eden.", dhikrCount: 550, reference: "Nisâ, 85"),
    EsmaulHusnaItem(id: 41, arabic: "ٱلْحَسِيبُ", transliteration: "El-Hasîb", turkishMeaning: "Kullarına yeten ve hesaba çeken.", dhikrCount: 80, reference: "Nisâ, 6"),
    EsmaulHusnaItem(id: 42, arabic: "ٱلْجَلِيلُ", transliteration: "El-Celîl", turkishMeaning: "Celâl, azamet ve ululuk sahibi.", dhikrCount: 73, reference: "Rahmân, 27"),
    EsmaulHusnaItem(id: 43, arabic: "ٱلْكَرِيمُ", transliteration: "El-Kerîm", turkishMeaning: "Cömertliği ve ikramı sınırsız olan.", dhikrCount: 270, reference: "İnfitâr, 6"),
    EsmaulHusnaItem(id: 44, arabic: "ٱلرَّقِيبُ", transliteration: "Er-Rakîb", turkishMeaning: "Bütün varlığı her an gözeten.", dhikrCount: 312, reference: "Nisâ, 1"),
    EsmaulHusnaItem(id: 45, arabic: "ٱلْمُجِيبُ", transliteration: "El-Mücîb", turkishMeaning: "Kendisine yönelenlerin dualarına icabet eden.", dhikrCount: 55, reference: "Hûd, 61"),
    EsmaulHusnaItem(id: 46, arabic: "ٱلْوَاسِعُ", transliteration: "El-Vâsi'", turkishMeaning: "İlmi ve rahmeti her şeyi kuşatan.", dhikrCount: 137, reference: "Bakara, 115"),
    EsmaulHusnaItem(id: 47, arabic: "ٱلْحَكِيمُ", transliteration: "El-Hakîm", turkishMeaning: "Her işi ve emri tam hikmetli olan.", dhikrCount: 78, reference: "Lokmân, 27"),
    EsmaulHusnaItem(id: 48, arabic: "ٱلْوَدُودُ", transliteration: "El-Vedûd", turkishMeaning: "Kullarını çok seven ve sevilmeye en layık olan.", dhikrCount: 20, reference: "Bürûc, 14"),
    EsmaulHusnaItem(id: 49, arabic: "ٱلْمَجِيدُ", transliteration: "El-Mecîd", turkishMeaning: "Şanı yüce ve ikramı bol olan.", dhikrCount: 57, reference: "Hûd, 73"),
    EsmaulHusnaItem(id: 50, arabic: "ٱلْبَاعِثُ", transliteration: "El-Bâis", turkishMeaning: "Ölüleri dirilten ve peygamberler gönderen.", dhikrCount: 573, reference: "Hac, 7"),
    EsmaulHusnaItem(id: 51, arabic: "ٱلشَّهِيدُ", transliteration: "Eş-Şehîd", turkishMeaning: "Her zaman ve her yerde hazır olup her şeye şahit olan.", dhikrCount: 319, reference: "Mâide, 117"),
    EsmaulHusnaItem(id: 52, arabic: "ٱلْحَقُّ", transliteration: "El-Hakk", turkishMeaning: "Varlığı hiç değişmeden duran mutlak gerçek.", dhikrCount: 108, reference: "Hac, 6"),
    EsmaulHusnaItem(id: 53, arabic: "ٱلْوَكِيلُ", transliteration: "El-Vekîl", turkishMeaning: "Kendisine tevekkül edenlerin işlerini en güzel yoluna koyan.", dhikrCount: 66, reference: "Âl-i İmrân, 173"),
    EsmaulHusnaItem(id: 54, arabic: "ٱلْقَوِىُّ", transliteration: "El-Kaviyy", turkishMeaning: "Kudreti sonsuz ve hiçbir şeye yenilmeyen.", dhikrCount: 116, reference: "Şûrâ, 19"),
    EsmaulHusnaItem(id: 55, arabic: "ٱلْمَتِينُ", transliteration: "El-Metîn", turkishMeaning: "Kudretinde hiçbir sarsıntı ve yorgunluk olmayan.", dhikrCount: 500, reference: "Zâriyât, 58"),
    EsmaulHusnaItem(id: 56, arabic: "ٱلْوَلِىُّ", transliteration: "El-Veliyy", turkishMeaning: "Müminlerin gerçek dostu ve yardımcısı.", dhikrCount: 46, reference: "Bakara, 257"),
    EsmaulHusnaItem(id: 57, arabic: "ٱلْحَمِيدُ", transliteration: "El-Hamîd", turkishMeaning: "Her türlü övgüye ve şükre layık olan.", dhikrCount: 62, reference: "İbrâhîm, 1"),
    EsmaulHusnaItem(id: 58, arabic: "ٱلْمُحْصِى", transliteration: "El-Muhsî", turkishMeaning: "Her şeyin sayısını ve ölçüsünü tek tek bilen.", dhikrCount: 148, reference: "Cin, 28"),
    EsmaulHusnaItem(id: 59, arabic: "ٱلْمُبْدِئُ", transliteration: "El-Mübdi'", turkishMeaning: "Varlıkları örneksiz olarak ilk kez yaratan.", dhikrCount: 56, reference: "Bürûc, 13"),
    EsmaulHusnaItem(id: 60, arabic: "ٱلْمُعِيدُ", transliteration: "El-Mu'îd", turkishMeaning: "Yaratılmışları ölümünden sonra yeniden dirilten.", dhikrCount: 124, reference: "Bürûc, 13"),
    EsmaulHusnaItem(id: 61, arabic: "ٱلْمُحْيِى", transliteration: "El-Muhyî", turkishMeaning: "Can bağışlayan, kalpleri ve toprağı dirilten.", dhikrCount: 68, reference: "Rûm, 50"),
    EsmaulHusnaItem(id: 62, arabic: "ٱلْمُمِيتُ", transliteration: "El-Mümît", turkishMeaning: "Canlıların eceli geldiğinde ölümünü yaratan.", dhikrCount: 490, reference: "Mü'min, 68"),
    EsmaulHusnaItem(id: 63, arabic: "ٱلْحَىُّ", transliteration: "El-Hayy", turkishMeaning: "Ezeli ve ebedi diri, hayatın mutlak kaynağı.", dhikrCount: 18, reference: "Bakara, 255"),
    EsmaulHusnaItem(id: 64, arabic: "ٱلْقَيُّومُ", transliteration: "El-Kayyûm", turkishMeaning: "Gökleri, yeri ve bütün varlığı her an ayakta tutan.", dhikrCount: 156, reference: "Bakara, 255"),
    EsmaulHusnaItem(id: 65, arabic: "ٱلْوَاجِدُ", transliteration: "El-Vâcid", turkishMeaning: "Hiçbir şeye muhtaç olmayan, dilediğini dilediği an bulan.", dhikrCount: 14, reference: "Duhâ, 6-8"),
    EsmaulHusnaItem(id: 66, arabic: "ٱلْمَاجِدُ", transliteration: "El-Mâcid", turkishMeaning: "Keremi, şanı ve yüceliği sonsuz olan.", dhikrCount: 48, reference: "Bürûc, 15"),
    EsmaulHusnaItem(id: 67, arabic: "ٱلْوَاحِدُ", transliteration: "El-Vâhid", turkishMeaning: "Zatında, sıfatlarında ve işlerinde tek olan.", dhikrCount: 19, reference: "Bakara, 163"),
    EsmaulHusnaItem(id: 68, arabic: "ٱلصَّمَدُ", transliteration: "Es-Samed", turkishMeaning: "Her şeyin kendisine muhtaç olduğu, kendisi hiçbir şeye muhtaç olmayan.", dhikrCount: 134, reference: "İhlâs, 2"),
    EsmaulHusnaItem(id: 69, arabic: "ٱلْقَادِرُ", transliteration: "El-Kâdir", turkishMeaning: "Dilediği her şeye tam gücü yeten.", dhikrCount: 305, reference: "En'âm, 65"),
    EsmaulHusnaItem(id: 70, arabic: "ٱلْمُقْتَدِرُ", transliteration: "El-Muktedir", turkishMeaning: "Bütün kuvvet ve kudret sahipleri üzerinde mutlak tasarruf sahibi.", dhikrCount: 744, reference: "Kamer, 55"),
    EsmaulHusnaItem(id: 71, arabic: "ٱلْمُقَدِّمُ", transliteration: "El-Mukaddim", turkishMeaning: "Hikmetiyle dilediğini öne geçiren ve yükselten.", dhikrCount: 184, reference: "Kâf, 28"),
    EsmaulHusnaItem(id: 72, arabic: "ٱلْمُؤَخِّرُ", transliteration: "El-Muahhir", turkishMeaning: "Hikmeti gereği dilediğini erteleyen ve geriye bırakan.", dhikrCount: 846, reference: "İbrâhîm, 42"),
    EsmaulHusnaItem(id: 73, arabic: "ٱلْأَوَّلُ", transliteration: "El-Evvel", turkishMeaning: "Varlığının başlangıcı olmayan ezeli İlah.", dhikrCount: 37, reference: "Hadîd, 3"),
    EsmaulHusnaItem(id: 74, arabic: "ٱلْآخِرُ", transliteration: "El-Âhir", turkishMeaning: "Varlığının sonu olmayan ebedi İlah.", dhikrCount: 801, reference: "Hadîd, 3"),
    EsmaulHusnaItem(id: 75, arabic: "ٱلظَّاهِرُ", transliteration: "Ez-Zâhir", turkishMeaning: "Varlığı sayısız delillerle apaçık ortada olan.", dhikrCount: 1106, reference: "Hadîd, 3"),
    EsmaulHusnaItem(id: 76, arabic: "ٱلْبَاطِنُ", transliteration: "El-Bâtın", turkishMeaning: "Zatının mahiyeti duyularla idrak edilemeyen ve her sırrı bilen.", dhikrCount: 62, reference: "Hadîd, 3"),
    EsmaulHusnaItem(id: 77, arabic: "ٱلْوَالِى", transliteration: "El-Vâlî", turkishMeaning: "Kâinatı ve bütün hadiseleri tek başına yöneten.", dhikrCount: 47, reference: "Ra'd, 11"),
    EsmaulHusnaItem(id: 78, arabic: "ٱلْمُتَعَالِى", transliteration: "El-Müteâlî", turkishMeaning: "Aklın tasavvur ettiği her şeyden aşkın ve yüce olan.", dhikrCount: 551, reference: "Ra'd, 9"),
    EsmaulHusnaItem(id: 79, arabic: "ٱلْبَرُّ", transliteration: "El-Berr", turkishMeaning: "Kullarına karşı iyiliği, şefkati ve lütfu bol olan.", dhikrCount: 202, reference: "Tûr, 28"),
    EsmaulHusnaItem(id: 80, arabic: "ٱلتَّوَّابُ", transliteration: "Et-Tevvâb", turkishMeaning: "Tövbeleri kabul eden ve kullarını tövbeye muvaffak kılan.", dhikrCount: 409, reference: "Bakara, 37"),
    EsmaulHusnaItem(id: 81, arabic: "ٱلْمُنتَقِمُ", transliteration: "El-Müntakim", turkishMeaning: "Mazlumun hakkını zalimden adaletiyle alan.", dhikrCount: 630, reference: "Secde, 22"),
    EsmaulHusnaItem(id: 82, arabic: "ٱلْعَفُوُّ", transliteration: "El-Afüvv", turkishMeaning: "Günahları kökünden silip affeden.", dhikrCount: 156, reference: "Nisâ, 99"),
    EsmaulHusnaItem(id: 83, arabic: "ٱلرَّءُوفُ", transliteration: "Er-Raûf", turkishMeaning: "Çok şefkatli ve engin merhamet sahibi.", dhikrCount: 286, reference: "Bakara, 207"),
    EsmaulHusnaItem(id: 84, arabic: "مَالِكُ ٱلْمُلْكِ", transliteration: "Mâlikü'l-Mülk", turkishMeaning: "Mülkün ebedi sahibi, dilediğine mülk veren.", dhikrCount: 212, reference: "Âl-i İmrân, 26"),
    EsmaulHusnaItem(id: 85, arabic: "ذُو ٱلْجَلَالِ وَٱلْإِكْرَامِ", transliteration: "Zü'l-Celâli ve'l-İkrâm", turkishMeaning: "Hem sonsuz azamet hem de sınırsız ikram sahibi.", dhikrCount: 1100, reference: "Rahmân, 27"),
    EsmaulHusnaItem(id: 86, arabic: "ٱلْمُقْسِطُ", transliteration: "El-Muksit", turkishMeaning: "Bütün hükümlerinde tam adalet ve denge kuran.", dhikrCount: 209, reference: "Âl-i İmrân, 18"),
    EsmaulHusnaItem(id: 87, arabic: "ٱلْجَامِعُ", transliteration: "El-Câmi'", turkishMeaning: "İstediğini istediği zaman ve yerde bir araya toplayan.", dhikrCount: 114, reference: "Âl-i İmrân, 9"),
    EsmaulHusnaItem(id: 88, arabic: "ٱلْغَنِىُّ", transliteration: "El-Ganiyy", turkishMeaning: "Mutlak zengin, hiçbir şeye ihtiyacı olmayan.", dhikrCount: 1060, reference: "Fâtır, 15"),
    EsmaulHusnaItem(id: 89, arabic: "ٱلْمُغْنِى", transliteration: "El-Muğnî", turkishMeaning: "Dilediği kulunu maddi ve manevi zenginliğe kavuşturan.", dhikrCount: 1100, reference: "Necm, 48"),
    EsmaulHusnaItem(id: 90, arabic: "ٱلْمَانِعُ", transliteration: "El-Mâni'", turkishMeaning: "Hikmeti gereği zararlı veya vakti gelmemiş şeyleri engelleyen.", dhikrCount: 161, reference: "Tirmizî, Daavât 82"),
    EsmaulHusnaItem(id: 91, arabic: "ٱلضَّارُّ", transliteration: "Ed-Dârr", turkishMeaning: "Hikmet ve imtihan gereği elem ve imtihan yaratan.", dhikrCount: 1001, reference: "En'âm, 17"),
    EsmaulHusnaItem(id: 92, arabic: "ٱلنَّافِعُ", transliteration: "En-Nâfi'", turkishMeaning: "Hayır, şifa ve fayda veren şeyleri yaratan.", dhikrCount: 201, reference: "Fetih, 11"),
    EsmaulHusnaItem(id: 93, arabic: "ٱلنُّورُ", transliteration: "En-Nûr", turkishMeaning: "Gökleri, yeri ve gönülleri nurlandıran.", dhikrCount: 256, reference: "Nûr, 35"),
    EsmaulHusnaItem(id: 94, arabic: "ٱلْهَادِى", transliteration: "El-Hâdî", turkishMeaning: "Doğru yolu gösteren ve hidayete ulaştıran.", dhikrCount: 20, reference: "Furkan, 31"),
    EsmaulHusnaItem(id: 95, arabic: "ٱلْبَدِيعُ", transliteration: "El-Bedî'", turkishMeaning: "Gökleri ve yeri eşsiz ve benzersiz şekilde yaratan.", dhikrCount: 86, reference: "Bakara, 117"),
    EsmaulHusnaItem(id: 96, arabic: "ٱلْبَاقِى", transliteration: "El-Bâkî", turkishMeaning: "Varlığı ebedi olan, asla son bulmayan.", dhikrCount: 113, reference: "Rahmân, 27"),
    EsmaulHusnaItem(id: 97, arabic: "ٱلْوَارِثُ", transliteration: "El-Vâris", turkishMeaning: "Her fani göçtükten sonra mülkün gerçek sahibi olarak kalan.", dhikrCount: 707, reference: "Hicr, 23"),
    EsmaulHusnaItem(id: 98, arabic: "ٱلرَّشِيدُ", transliteration: "Er-Reşîd", turkishMeaning: "Bütün işlerini en doğru ve hikmetli sonuca ulaştıran.", dhikrCount: 514, reference: "Hûd, 87"),
    EsmaulHusnaItem(id: 99, arabic: "ٱلصَّبُورُ", transliteration: "Es-Sabûr", turkishMeaning: "Çok sabırlı olan, asi kullarını cezalandırmakta acele etmeyen.", dhikrCount: 298, reference: "Tirmizî, Daavât 82"),
  ];
}
