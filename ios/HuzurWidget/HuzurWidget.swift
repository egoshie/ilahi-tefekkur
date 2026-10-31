import WidgetKit
import SwiftUI

struct HuzurVerseEntry: TimelineEntry {
    let date: Date
    let arabic: String
    let turkish: String
    let reference: String
}

struct HuzurTimelineProvider: TimelineProvider {
    let verses: [(ar: String, tr: String, ref: String)] = [
        ("مَا وَدَّعَكَ رَبُّكَ", "Rabbin seni terk etmedi.", "Duhâ, 3"),
        ("إِنَّ مَعَ ٱلْعُسْرِ يُسْرًا", "Zorlukla beraber kolaylık vardır.", "İnşirah, 6"),
        ("إِنَّ ٱللَّهَ مَعَ ٱلصَّـٰبِرِينَ", "Allah sabredenlerle beraberdir.", "Bakara, 153"),
        ("لَا تَحْزَنْ إِنَّ ٱللَّهَ مَعَنَا", "Üzülme! Allah bizimledir.", "Tevbe, 40"),
        ("فَٱذْكُرُونِىٓ أَذْكُرْكُمْ", "Beni anın ki sizi anayım.", "Bakara, 152"),
        ("وَهُوَ عَلَىٰ كُلِّ شَىْءٍ قَدِيرٌ", "O, her şeye kadirdir.", "Mülk, 1"),
        ("كُلُّ نَفْسٍ ذَآئِقَةُ ٱلْمَوْتِ", "Her nefis ölümü tadacaktır.", "Âl-i İmrân, 185"),
        ("أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ", "Kalpler Allah'ı anmakla huzur bulur.", "Ra'd, 28"),
        ("وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ ٱلْوَرِيدِ", "Biz ona şah damarından yakınız.", "Kâf, 16"),
        ("لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ", "Allah'ın rahmetinden ümit kesmeyin.", "Zümer, 53"),
        ("وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ", "Rabbin sana verecek ve razı olacaksın.", "Duhâ, 5"),
        ("حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ", "Allah bize yeter, O ne güzel vekildir.", "Âl-i İmrân, 173"),
        ("ٱدْعُونِىٓ أَسْتَجِبْ لَكُمْ", "Bana dua edin, size icabet edeyim.", "Mü'min, 60"),
        ("فَإِنِّى قَرِيبٌ", "Şüphesiz Ben çok yakınım.", "Bakara, 186"),
        ("لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ", "Şükrederseniz nimetimi artırırım.", "İbrâhîm, 7"),
        ("وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥ", "Allah'a tevekkül edene O yeter.", "Talâk, 3"),
        ("إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", "Yalnız Sana kulluk ederiz.", "Fâtiha, 5"),
        ("وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ", "Nerede olursanız olun O sizinledir.", "Hadîd, 4"),
        ("لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا", "Allah kimseye gücünden fazlasını yüklemez.", "Bakara, 286"),
        ("وَإِلَىٰ رَبِّكَ فَٱرْغَب", "Yalnızca Rabbine yönel.", "İnşirah, 8"),
        ("أَن يَقُولَ لَهُۥ كُن فَيَكُونُ", "O'nun emri Ol! demektir, hemen olur.", "Yâsîn, 82"),
        ("ٱللَّهُ نُورُ ٱلسَّمَـٰوَٰتِ وَٱلْأَرْضِ", "Allah göklerin ve yerin nûrudur.", "Nûr, 35"),
        ("فَفِرُّوٓا۟ إِلَى ٱللَّهِ", "Öyleyse Allah'a koşun!", "Zâriyât, 50"),
        ("إِنَّ ٱللَّهَ يُحِبُّ ٱلْمُتَوَكِّلِينَ", "Allah tevekkül edenleri sever.", "Âl-i İmrân, 159"),
        ("إِنَّ ٱللَّهَ يُحِبُّ ٱلْمُحْسِنِينَ", "Allah iyilik edenleri sever.", "Bakara, 195"),
        ("فَمَن يَعْمَلْ مِثْقَالَ ذَرَّةٍ خَيْرًا يَرَهُۥ", "Zerre kadar iyilik yapan karşılığını görür.", "Zilzâl, 7"),
        ("قُلْ هُوَ ٱللَّهُ أَحَدٌ", "De ki: O Allah tektir.", "İhlâs, 1"),
        ("ٱللَّهُ ٱلصَّمَدُ", "Her şey O'na muhtaçtır.", "İhlâs, 2"),
        ("سَيَجْعَلُ ٱللَّهُ بَعْدَ عُسْرٍ يُسْرًا", "Allah zorluğun ardından kolaylık verir.", "Talâk, 7"),
        ("وَمَا كَانَ رَبُّكَ نَسِيًّا", "Senin Rabbin asla unutkan değildir.", "Meryem, 64"),
        ("وَرَحْمَتِى وَسِعَتْ كُلَّ شَىْءٍ", "Rahmetim her şeyi kuşatmıştır.", "A'râf, 156"),
        ("ٱللَّهُ لَطِيفٌۢ بِعِبَادِهِۦ", "Allah kullarına çok lütufkârdır.", "Şûrâ, 19"),
        ("إِنَّا لِلَّهِ وَإِنَّآ إِلَيْهِ رَٰجِعُونَ", "Biz Allah'a aidiz ve O'na döneceğiz.", "Bakara, 156"),
        ("وَٱصْبِرْ وَمَا صَبْرُكَ إِلَّا بِٱللَّهِ", "Sabret! Sabrın ancak Allah'ın yardımıyladır.", "Nahl, 127"),
        ("إِنَّ رَبِّى قَرِيبٌ مُّجِيبٌ", "Rabbim yakındır, dualara icabet edendir.", "Hûd, 61"),
        ("وَكَفَىٰ بِٱللَّهِ وَكِيلًا", "Vekil olarak Allah yeter.", "Ahzâb, 3"),
        ("رَّبِّ زِدْنِى عِلْمًا", "Rabbim! İlmimi artır.", "Tâhâ, 114"),
        ("إِنَّ ٱللَّهَ غَفُورٌ رَّحِيمٌ", "Şüphesiz Allah çok bağışlayandır.", "Bakara, 173"),
        ("فَٱللَّهُ خَيْرٌ حَـٰفِظًا", "Allah en hayırlı koruyucudur.", "Yûsuf, 64"),
        ("سَلَـٰمٌ قَوْلًا مِّن رَّبٍّ رَّحِيمٍ", "Merhametli Rab'den Selâm! vardır.", "Yâsîn, 58"),
        ("وَٱسْتَعِينُوا۟ بِٱلصَّبْرِ وَٱلصَّلَوٰةِ", "Sabır ve namazla yardım dileyin.", "Bakara, 45"),
        ("وَلَا تَهِنُوا۟ وَلَا تَحْزَنُوا۟", "Gevşemeyin, asla hüzünlenmeyin.", "Âl-i İmrân, 139"),
        ("وَمَا تَوْفِيقِىٓ إِلَّا بِٱللَّهِ", "Başarım ancak Allah'ın yardımıyladır.", "Hûd, 88"),
        ("وَلَا تَا۟يْـَٔسُوا۟ مِن رَّوْحِ ٱللَّهِ", "Allah'ın rahmetinden ümit kesmeyin.", "Yûsuf, 87"),
        ("إِنَّ ٱللَّهَ يَأْمُرُ بِٱلْعَدْلِ وَٱلْإِحْسَـٰنِ", "Allah adaleti ve iyiliği emreder.", "Nahl, 90"),
        ("رَبِّ ٱشْرَحْ لِى صَدْرِى", "Rabbim! Göğsümü aç, işimi kolaylaştır.", "Tâhâ, 25"),
        ("لَّآ إِلَـٰهَ إِلَّآ أَنتَ سُبْحَـٰنَكَ", "Senden başka ilah yoktur.", "Enbiyâ, 87"),
        ("وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ", "Bana şifa veren ancak O'dur.", "Şuarâ, 80"),
        ("رَبِّ إِنِّى لِمَآ أَنزَلْتَ إِلَىَّ مِنْ خَيْرٍ فَقِيرٌ", "Rabbim! İndireceğin her hayra muhtacım.", "Kasas, 24"),
        ("وَإِنَّ ٱللَّهَ لَمَعَ ٱلْمُحْسِنِينَ", "Allah iyilik yapanlarla beraberdir.", "Ankebût, 69"),
        ("مَّا يَفْتَحِ ٱللَّهُ لِلنَّاسِ مِن رَّحْمَةٍ", "Allah'ın rahmet kapısını kimse kapatamaz.", "Fâtır, 2"),
        ("إِنَّمَا يُوَفَّى ٱلصَّـٰبِرُونَ أَجْرَهُم", "Sabredenlerin mükâfatı hesapsız verilir.", "Zümer, 10"),
        ("وَأُفَوِّضُ أَمْرِىٓ إِلَى ٱللَّهِ", "Ben işimi Allah'a havale ediyorum.", "Mü'min, 44"),
        ("ٱدْفَعْ بِٱلَّتِى هِىَ أَحْسَنُ", "Kötülüğü en güzel olan iyilikle sav.", "Fussilet, 34"),
        ("هَلْ جَزَآءُ ٱلْإِحْسَـٰنِ إِلَّا ٱلْإِحْسَـٰنُ", "İyiliğin karşılığı iyilikten başka mıdır?", "Rahmân, 60"),
        ("وَمَن يُؤْمِنۢ بِٱللَّهِ يَهْدِ قَلْبَهُۥ", "Allah inananın kalbini doğruya iletir.", "Teğâbün, 11"),
        ("قَدْ أَفْلَحَ مَن تَزَكَّىٰ", "Arınan kimse kurtuluşa ermiştir.", "A'lâ, 14")
    ]

    func placeholder(in context: Context) -> HuzurVerseEntry {
        HuzurVerseEntry(
            date: Date(),
            arabic: "مَا وَدَّعَكَ رَبُّكَ",
            turkish: "Rabbin seni terk etmedi.",
            reference: "Duhâ, 3"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HuzurVerseEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HuzurVerseEntry>) -> Void) {
        var entries: [HuzurVerseEntry] = []
        let now = Date()
        let cal = Calendar.current
        let baseHour = (Int(now.timeIntervalSince1970) / 3600)

        let shared = UserDefaults(suiteName: "group.com.ilahi.tefekkur")
        let customTr = shared?.string(forKey: "hourly_translation") ?? ""
        let customAr = shared?.string(forKey: "hourly_arabic") ?? ""
        let customRef = shared?.string(forKey: "hourly_reference") ?? ""

        for offset in 0 ..< 24 {
            let entryDate = cal.date(byAdding: .hour, value: offset, to: now) ?? now
            if offset == 0 && !customTr.isEmpty {
                entries.append(
                    HuzurVerseEntry(
                        date: entryDate,
                        arabic: customAr,
                        turkish: customTr,
                        reference: customRef
                    )
                )
            } else {
                let item = verses[(baseHour + offset) % verses.count]
                entries.append(
                    HuzurVerseEntry(
                        date: entryDate,
                        arabic: item.ar,
                        turkish: item.tr,
                        reference: item.ref
                    )
                )
            }
        }

        let nextReload = cal.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(nextReload)))
    }
}

extension View {
    @ViewBuilder
    func applyGlassBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.07, blue: 0.12),
                        Color(red: 0.04, green: 0.15, blue: 0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            self
        }
    }
}

struct HuzurKisaAyetWidgetView: View {
    var entry: HuzurTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Text(entry.turkish + " • " + entry.reference)
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 1) {
                        Text("HUZUR")
                            .font(.system(size: 8, weight: .bold))
                        Text(entry.reference)
                            .font(.system(size: 8.5, weight: .semibold))
                            .minimumScaleFactor(0.65)
                            .multilineTextAlignment(.center)
                    }
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.turkish)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(3)
                        .minimumScaleFactor(0.62)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("— " + entry.reference)
                        .font(.system(size: 9.5, weight: .bold))
                        .opacity(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Huzur")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.51))
                        Spacer()
                        Text(entry.reference)
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Color(red: 0.39, green: 1.0, blue: 0.85))
                    }
                    Spacer(minLength: 2)
                    Text(entry.turkish)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.65)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
            }
        }
        .applyGlassBackground()
    }
}

struct HuzurGenisAyetWidgetView: View {
    var entry: HuzurTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    if !entry.arabic.isEmpty {
                        Text(entry.arabic)
                            .font(.system(size: 12.5, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                    }
                    Text(entry.turkish)
                        .font(.system(size: 11.5, weight: .semibold))
                        .lineLimit(3)
                        .minimumScaleFactor(0.62)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("— " + entry.reference)
                        .font(.system(size: 9.5, weight: .medium))
                        .opacity(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Günün İlhamı")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.51))
                        Spacer()
                        Text(entry.reference)
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(Color(red: 0.39, green: 1.0, blue: 0.85))
                    }
                    Spacer(minLength: 2)
                    if !entry.arabic.isEmpty {
                        Text(entry.arabic)
                            .font(.system(size: family == .systemMedium ? 20 : 15, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.96, blue: 0.88))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                    }
                    Text(entry.turkish)
                        .font(.system(size: family == .systemMedium ? 14 : 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.65)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(family == .systemMedium ? 14 : 10)
            }
        }
        .applyGlassBackground()
    }
}

struct HuzurKisaAyetWidget: Widget {
    let kind: String = "HuzurKisaAyetWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HuzurTimelineProvider()) { entry in
            HuzurKisaAyetWidgetView(entry: entry)
        }
        .configurationDisplayName("Huzur • Saatlik Ayet")
        .description("Kilit ekranında ve ana ekranda kesilmeyen saatlik kısa ayet kartı.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular, .systemSmall])
    }
}

struct HuzurGenisAyetWidget: Widget {
    let kind: String = "HuzurGenisAyetWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HuzurTimelineProvider()) { entry in
            HuzurGenisAyetWidgetView(entry: entry)
        }
        .configurationDisplayName("Huzur • Geniş İlham Kartı")
        .description("Arapça hat ve Türkçe meal içeren geniş kilit ekranı ve ana ekran kartı.")
        .supportedFamilies([.systemMedium, .systemSmall, .accessoryRectangular])
    }
}

@main
struct HuzurWidgetBundle: WidgetBundle {
    var body: some Widget {
        HuzurKisaAyetWidget()
        HuzurGenisAyetWidget()
    }
}
