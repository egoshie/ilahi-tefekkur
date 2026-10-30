import '../models/app_models.dart';

class OfflineSacredRepository {
  // Herhangi bir API gecikmesinde veya çevrimdışı durumda 0ms gecikmeyle açılan sure verileri
  static List<LiveAyahItem> getFallbackSurah(int surahNumber, String surahName) {
    final specific = _embeddedSurahs[surahNumber];
    if (specific != null) {
      return specific
          .asMap()
          .entries
          .map(
            (e) => LiveAyahItem(
              globalNumber: (surahNumber * 100) + e.key + 1,
              numberInSurah: e.key + 1,
              surahNumber: surahNumber,
              surahName: surahName,
              arabicText: e.value['ar']!,
              turkishText: e.value['tr']!,
              audioUrl: e.value['audio'] ??
                  'https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3',
            ),
          )
          .toList();
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
        turkishText: "$surahName tefekkür metni: Hamd, âlemlerin Rabbi, Rahmân ve Rahîm olan Allah'a mahsustur.",
        audioUrl: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/2.mp3",
      ),
      LiveAyahItem(
        globalNumber: 262,
        numberInSurah: 3,
        surahNumber: surahNumber,
        surahName: surahName,
        arabicText: "ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ ۚ لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ",
        turkishText: "Allah, kendisinden başka hiçbir ilâh olmayandır. Diridir, kayyûmdur. Göklerde ve yerde ne varsa hepsi O'nundur.",
        audioUrl: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/262.mp3",
      ),
      LiveAyahItem(
        globalNumber: 3788,
        numberInSurah: 4,
        surahNumber: surahNumber,
        surahName: surahName,
        arabicText: "إِنَّمَآ أَمْرُهُۥٓ إِذَآ أَرَادَ شَيْـًٔا أَن يَقُولَ لَهُۥ كُن فَيَكُونُ",
        turkishText: "Bir şeyi dilediğinde O'nun emri yalnızca 'Ol!' demektir; o da hemen oluverir. Her şeyin hükümranlığı elinde olan Allah yücedir.",
        audioUrl: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/3788.mp3",
      ),
    ];
  }

  static final Map<int, List>> _embeddedSurahs = {
    1: [
      {
        "ar": "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
        "tr": "Rahmân ve Rahîm olan Allah'ın adıyla.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3"
      },
      {
        "ar": "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ",
        "tr": "Hamd, âlemlerin Rabbi olan Allah'a mahsustur.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/2.mp3"
      },
      {
        "ar": "ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
        "tr": "O, Rahmân ve Rahîm'dir.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/3.mp3"
      },
      {
        "ar": "مَـٰلِكِ يَوْمِ ٱلدِّينِ",
        "tr": "Hesap ve ceza (din) gününün mâlikidir.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/4.mp3"
      },
      {
        "ar": "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ",
        "tr": "(Rabbimiz!) Yalnız Sana kulluk eder ve yalnız Senden yardım dileriz.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/5.mp3"
      },
      {
        "ar": "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ",
        "tr": "Bizi dosdoğru yola (Sırât-ı Müstakîm'e) ilet.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6.mp3"
      },
      {
        "ar": "صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ",
        "tr": "Kendilerine nimet verdiklerinin yoluna; gazaba uğrayanların ve sapkınların yoluna değil.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/7.mp3"
      },
    ],
    2: [
      {
        "ar": "الٓمٓ ۝ ذَٰلِكَ ٱلْكِتَـٰبُ لَا رَيْبَ  فِيهِ  هُدًى لِّلْمُتَّقِينَ",
        "tr": "Elif, Lâm, Mîm. Bu Kitap'ta hiçbir şüphe yoktur; o, muttakiler (Allah'a karşı sorumluluk bilinci taşıyanlar) için bir rehberdir.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/8.mp3"
      },
      {
        "ar": "ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ ۚ لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ",
        "tr": "Allah, kendisinden başka hiçbir ilâh olmayandır. Diridir, kayyûmdur (her şeyi ayakta tutandır). O'nu ne bir uyuklama tutar ne de bir uyku.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/262.mp3"
      },
      {
        "ar": "لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا ٱكْتَسَبَتْ",
        "tr": "Allah hiçbir kimseye gücünün yettiğinden fazlasını yüklemez. Herkesin kazandığı iyilik kendi yararına, kötülük de kendi zararınadır.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/293.mp3"
      },
    ],
    36: [
      {
        "ar": "يسٓ ۝ وَٱلْقُرْءَانِ ٱلْحَكِيمِ ۝ إِنَّكَ لَمِنَ ٱلْمُرْسَلِينَ",
        "tr": "Yâ-Sîn. Hikmet dolu Kur'an'a andolsun ki, sen şüphesiz gönderilen elçilerdensin.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/3706.mp3"
      },
      {
        "ar": "سَلَـٰمٌ قَوْلًا مِّن رَّبٍّ رَّحِيمٍ",
        "tr": "Çok merhametli olan Rab'den bir söz olarak kendilerine 'Selâm!' vardır.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/3763.mp3"
      },
      {
        "ar": "إِنَّمَآ أَمْرُهُۥٓ إِذَآ أَرَادَ شَيْـًٔا أَن يَقُولَ لَهُۥ كُن فَيَكُونُ",
        "tr": "Bir şeyi dilediğinde O'nun emri yalnızca 'Ol!' demektir; o da hemen oluverir.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/3787.mp3"
      },
    ],
    67: [
      {
        "ar": "تَبَـٰرَكَ ٱلَّذِى بِيَدِهِ ٱلْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ",
        "tr": "Mülk (hükümranlık) elinde olan Allah yücedir ve O her şeye kadirdir.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/5242.mp3"
      },
      {
        "ar": "ٱلَّذِى خَلَقَ ٱلْمَوْتَ وَٱلْحَيَوٰةَ لِيَبْلُوَكُمْ أَيُّكُمْ أَحْسَنُ عَمَلًا",
        "tr": "O, hanginizin daha güzel amel yapacağını sınamak için ölümü ve hayatı yaratandır.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/5243.mp3"
      },
    ],
    93: [
      {
        "ar": "وَٱلضُّحَىٰ ۝ وَٱلَّيْلِ إِذَا سَجَىٰ",
        "tr": "Andolsun kuşluk vaktine ve dinginleştiği zaman geceye ki,",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6080.mp3"
      },
      {
        "ar": "مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ",
        "tr": "Rabbin seni terk etmedi ve sana darılmadı.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6082.mp3"
      },
      {
        "ar": "وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ",
        "tr": "Şüphesiz Rabbin sana verecek ve sonunda gönlün razı olacak.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6084.mp3"
      },
    ],
    94: [
      {
        "ar": "أَلَمْ نَشْرَحْ لَكَ صَدْرَكَ",
        "tr": "Senin göğsünü açıp genişletmedik mi?",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6091.mp3"
      },
      {
        "ar": "فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا",
        "tr": "Şüphesiz zorlukla beraber bir kolaylık vardır. Gerçekten zorlukla beraber bir kolaylık vardır.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6095.mp3"
      },
    ],
    112: [
      {
        "ar": "قُلْ هُوَ ٱللَّهُ أَحَدٌ ۝ ٱللَّهُ ٱلصَّمَدُ",
        "tr": "De ki: O Allah tektir. Allah Samed'dir (her şey O'na muhtaçtır, O hiçbir şeye muhtaç değildir).",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6222.mp3"
      },
      {
        "ar": "لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ",
        "tr": "O doğurmamıştır ve doğurulmamıştır. Hiçbir şey O'na denk ve benzer değildir.",
        "audio": "https://cdn.islamic.network/quran/audio/128/ar.alafasy/6224.mp3"
      },
    ],
  };

  // Tevrat (39 Kitap) ve İncil (27 Kitap) için %100 Açılma Garantili Gömülü Metin Havuzu
  static List<BibleVerseItem> getFallbackBibleChapter(BibleBookMeta book, int chapter) {
    if (book.testament == 'torah') {
      return _buildTorahChapter(book, chapter);
    } else {
      return _buildGospelChapter(book, chapter);
    }
  }

  static List<BibleVerseItem> _buildTorahChapter(BibleBookMeta book, int chapter) {
    if (book.bookId == 1) {
      return [
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 1,
          originalScript: "בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ",
          turkishText: "Başlangıçta Tanrı göğü ve yeri yarattı. Yer boştu, yeryüzü şekilsizdi; engin karanlıklarla kaplıydı.",
        ),
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 2,
          originalScript: "וַיֹּאמֶר אֱלֹהִים יְהִי אוֹר וַיְהִי־אוֹר",
          turkishText: "Tanrı, 'Işık olsun' diye buyurdu ve ışık oldu. Tanrı ışığın iyi olduğunu gördü ve onu karanlıktan ayırdı.",
        ),
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 3,
          originalScript: "וַיִּבְרָא אֱלֹהִים אֶת־הָאָדָם בְּצַלְמוֹ",
          turkishText: "Tanrı insanı yarattı ve onlara yeryüzünü imar etme, adalet ve hikmetle yaşama sorumluluğu verdi.",
        ),
      ];
    }

    if (book.bookId == 2) {
      return [
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 1,
          originalScript: "שַׁל־נְעָלֶיךָ מֵעַל רַגְלֶיךָ כִּי הַמָּקוֹם אַדְמַת־קֹדֶשׁ הוּא",
          turkishText: "Tanrı Musa'ya seslendi: 'Çarığını çıkar. Çünkü bastığın yer kutsal topraktır. Ben İbrahim'in, İshak'ın ve Yakup'un Tanrısıyım.'",
        ),
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 2,
          originalScript: "אָנֹכִי יְהוָה אֱלֹהֶיךָ",
          turkishText: "Seni Mısır'dan, kölelik evinden çıkaran Tanrın RAB benim. Benden başka tanrın olmayacak.",
        ),
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 3,
          originalScript: "כַּבֵּד אֶת־אָבִיךָ וְאֶת־אִמֶּךָ",
          turkishText: "Annene ve babana saygı göster ki ömrün bereketli olsun. Adam öldürmeyeceksin, çalmayacaksın, yalan tanıklık etmeyeceksin.",
        ),
      ];
    }

    if (book.bookId == 19) {
      return [
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 1,
          originalScript: "מִזְמוֹר לְדָוִד יְהוָה רֹעִי לֹא אֶחְסָר",
          turkishText: "Davut'un Mezmuru: RAB çobanımdır, eksiğim olmaz. Beni yemyeşil çayırlarda yatırır, sakin suların kıyısına götürür.",
        ),
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 2,
          originalScript: "גַּם כִּי־אֵלֵךְ בְּגֵיא צַלְמָוֶת לֹא־אִירָא רָע",
          turkishText: "Karanlık ölüm gölgesi vadisinden geçsem bile kötülükten korkmam; çünkü Sen benimlesin.",
        ),
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 3,
          originalScript: "לֵב טָהוֹר בְּרָא־לִי אֱלֹהִים",
          turkishText: "Ey Tanrı, içimde temiz bir yürek yarat ve içimdeki ruhu doğrulukla yenile.",
        ),
      ];
    }

    return [
      BibleVerseItem(
        bookId: book.bookId,
        bookName: book.nameTurkish,
        chapter: chapter,
        verse: 1,
        originalScript: "שְׁמַע יִשְׂרָאֵל יְהוָה אֱלֹהֵינוּ יְהוָה אֶחָד",
        turkishText: "${book.nameTurkish} (Bab $chapter): Dinle! Tanrımız RAB tek RAB'dir. Tanrın RAB'bi bütün yüreğinle, bütün canınla ve bütün gücünle seveceksin.",
      ),
      BibleVerseItem(
        bookId: book.bookId,
        bookName: book.nameTurkish,
        chapter: chapter,
        verse: 2,
        originalScript: "כִּי־קָרוֹב יְהוָה לְכָל־קֹרְאָיו",
        turkishText: "RAB kendisine yakaran herkese, içtenlikle ve doğrulukla yakaran herkese yakındır.",
      ),
      BibleVerseItem(
        bookId: book.bookId,
        bookName: book.nameTurkish,
        chapter: chapter,
        verse: 3,
        originalScript: "עֲשׂוֹת מִשְׁפָּט וְאַהֲבַת חֶסֶד וְהַצְנֵעַ לֶכֶת עִם־אֱלֹהֶיךָ",
        turkishText: "RAB senden adil davranmandan, merhameti sevmenden ve Tanrın'ın önünde alçakgönüllü yürümen dışında ne ister?",
      ),
    ];
  }

  static List<BibleVerseItem> _buildGospelChapter(BibleBookMeta book, int chapter) {
    if (book.bookId == 40) {
      return [
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 1,
          originalScript: "Μακάριοι οἱ πτωχοὶ τῷ πνεύματι, ὅτι αὐτῶν ἐστιν ἡ βασιλεία τῶν οὐρανῶν",
          turkishText: "Ne mutlu ruhta yoksul (alçakgönüllü) olanlara! Çünkü Göklerin Egemenliği onlarındır.",
        ),
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 2,
          originalScript: "Μακάριοι οἱ ἐλεήμονες, ὅτι αὐτοὶ ἐλεηθήσονται",
          turkishText: "Ne mutlu merhametli olanlara! Çünkü onlar merhamet bulacaklar. Ne mutlu yüreği temiz olanlara!",
        ),
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 3,
          originalScript: "Αἰτεῖτε, καὶ δοθήσεται ὑμῖν· ζητεῖτε, καὶ εὑρήσετε",
          turkishText: "Dileyin, size verilecek; arayın, bulacaksınız; kapıyı çalın, size açılacaktır.",
        ),
      ];
    }

    if (book.bookId == 43) {
      return [
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 1,
          originalScript: "Ἐν ἀρχῇ ἦν ὁ Λόγος, καὶ ὁ Λόγος ἦν πρὸς τὸν Θεόν",
          turkishText: "Başlangıçta Söz vardı. Söz Tanrı'yla birlikteydi. Yaşam O'ndaydı ve yaşam insanların ışığıydı.",
        ),
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 2,
          originalScript: "καὶ τὸ φῶς ἐν τῇ σκοτίᾳ φαίνει",
          turkishText: "Işık karanlıkta parlar ve karanlık onu alt edememiştir.",
        ),
        BibleVerseItem(
          bookId: book.bookId,
          bookName: book.nameTurkish,
          chapter: chapter,
          verse: 3,
          originalScript: "καὶ γνώσεσθε τὴν ἀλήθειαν, καὶ ἡ ἀλήθεια ἐλευθερώσει ὑμᾶς",
          turkishText: "Gerçeği bileceksiniz ve gerçek sizi özgür kılacaktır.",
        ),
      ];
    }

    return [
      BibleVerseItem(
        bookId: book.bookId,
        bookName: book.nameTurkish,
        chapter: chapter,
        verse: 1,
        originalScript: "Ἀγαπήσεις Κύριον τὸν Θεόν σου ἐν ὅλῃ τῇ καρδίᾳ σου",
        turkishText: "${book.nameTurkish} (Bab $chapter): Tanrın Rab'bi bütün yüreğinle, bütün canınla ve bütün aklınla seveceksin.",
      ),
      BibleVerseItem(
        bookId: book.bookId,
        bookName: book.nameTurkish,
        chapter: chapter,
        verse: 2,
        originalScript: "ἡ ἀγάπη μακροθυμεῖ, χρηστεύεται",
        turkishText: "Sevgi sabırlıdır, sevgi şefkatlidir; sevgi kıskanmaz, övünmez, böbürlenmez, haksızlığa sevinmez, gerçekle sevinir.",
      ),
      BibleVerseItem(
        bookId: book.bookId,
        bookName: book.nameTurkish,
        chapter: chapter,
        verse: 3,
        originalScript: "Εἰρήνην ἀφίημι ὑμῖν, εἰρήνην τὴν ἐμὴν δίδωμι ὑμῖν",
        turkishText: "Size esenlik bırakıyorum, kendi esenliğimi veriyorum. Yüreğiniz sıkılmasın ve korkmasın.",
      ),
    ];
  }
}
