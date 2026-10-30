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
        ("أَن يَقُولَ لَهُۥ كُن فَيَكُونُ", "O'nun emri 'Ol!' demektir, hemen olur.", "Yâsîn, 82"),
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
        ("وَكفىٰ بِٱللَّهِ وَكِيلًا", "Vekil olarak Allah yeter.", "Ahzâb, 3"),
        ("رَّبِّ زِدْنِى عِلْمًا", "Rabbim! İlmimi artır.", "Tâhâ, 114"),
        ("إِنَّ ٱللَّهَ غَفُورٌ رَّحِيمٌ", "Şüphesiz Allah çok bağışlayandır.", "Bakara, 173"),
        ("وَٱللَّهُ خَيْرٌ حَـٰفِظًا", "Allah en hayırlı koruyucudur.", "Yûsuf, 64"),
        ("سَلَـٰمٌ قَوْلًا مِّن رَّبٍّ رَّحِيمٍ", "Merhametli Rab'den 'Selâm!' vardır.", "Yâsîn, 58")
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
        let baseHour = cal.component(.hour, from: now) + (cal.component(.day, from: now) * 24)

        for offset in 0 ..< 24 {
            let entryDate = cal.date(byAdding: .hour, value: offset, to: now) ?? now
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

        let nextReload = cal.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(nextReload)))
    }
}

extension View {
    @ViewBuilder
    func applyLiquidGlassWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                LinearGradient(
                    colors: [
                        Color(red: 0.01, green: 0.04, blue: 0.08),
                        Color(red: 0.03, green: 0.12, blue: 0.15),
                        Color(red: 0.04, green: 0.18, blue: 0.21)
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

struct HuzurWidgetEntryView: View {
    var entry: HuzurTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Text("\(entry.turkish) • \(entry.reference)")
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 1) {
                        Text("HUZUR")
                            .font(.system(size: 8, weight: .bold))
                        Text(entry.reference)
                            .font(.system(size: 9, weight: .semibold))
                            .multilineTextAlignment(.center)
                    }
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.arabic)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                    Text("\"\(entry.turkish)\"")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(2)
                    Text("— \(entry.reference)")
                        .font(.system(size: 10, weight: .medium))
                        .opacity(0.8)
                }
            default:
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Huzur")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.51))
                        Spacer()
                        Text(entry.reference)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.39, green: 1.0, blue: 0.85))
                    }
                    Spacer(minLength: 2)
                    Text(entry.arabic)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.96, blue: 0.88))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .lineLimit(1)
                    Text("\"\(entry.turkish)\"")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .padding(12)
            }
        }
        .applyLiquidGlassWidgetBackground()
    }
}

@main
struct HuzurWidget: Widget {
    let kind: String = "HuzurWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HuzurTimelineProvider()) { entry in
            HuzurWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Huzur • Saatlik Ayet")
        .description("Kilit ekranında ve ana ekranda her saat başı yenilenen kısa Kuran ayeti.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular,
            .systemSmall,
            .systemMedium
        ])
    }
}
