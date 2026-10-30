import WidgetKit
import SwiftUI

struct ShortVerseEntry: TimelineEntry {
    let date: Date
    let arabic: String
    let turkish: String
    let reference: String
}

struct HourlyShortVerseProvider: TimelineProvider {
    let pool: [(ar: String, tr: String, ref: String)] = [
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
        ("إِنَّا لِلَّهِ وَإِنَّآ إِلَيْهِ رَٰجِعُونَ", "Biz Allah'a aidiz ve O'na döneceğiz.", "Bakara, 156")
    ]

    func placeholder(in context: Context) -> ShortVerseEntry {
        ShortVerseEntry(
            date: Date(),
            arabic: "مَا وَدَّعَكَ رَبُّكَ",
            turkish: "Rabbin seni terk etmedi.",
            reference: "Duhâ, 3"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShortVerseEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShortVerseEntry>) -> Void) {
        var entries: [ShortVerseEntry] = []
        let currentDate = Date()
        let calendar = Calendar.current
        let baseHour = calendar.component(.hour, from: currentDate)

        for hourOffset in 0 ..< 24 {
            let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let idx = (baseHour + hourOffset) % pool.count
            let item = pool[idx]
            entries.append(
                ShortVerseEntry(
                    date: entryDate,
                    arabic: item.ar,
                    turkish: item.tr,
                    reference: item.ref
                )
            )
        }

        let nextUpdate = calendar.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct LockScreenVerseWidgetEntryView: View {
    var entry: HourlyShortVerseProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("\(entry.turkish) (\(entry.reference))")
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
                    .foregroundColor(.secondary)
            }
        default:
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.06, blue: 0.14),
                        Color(red: 0.05, green: 0.16, blue: 0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                VStack(alignment: .leading, spacing: 6) {
                    Text("SAATLİK KISA AYET")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.53))
                    Text(entry.arabic)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.51))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text("\"\(entry.turkish)\"")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("— \(entry.reference)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.0, green: 0.90, blue: 1.0))
                }
                .padding(14)
            }
        }
    }
}

@main
struct LockScreenVerseWidget: Widget {
    let kind: String = "LockScreenVerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HourlyShortVerseProvider()) { entry in
            LockScreenVerseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("İlahi Tefekkür • Saatlik Ayet")
        .description("Kilit ekranında her saat başı otomatik değişen kısa Kuran ayeti.")
        .supportedFamilies([
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
            .systemMedium
        ])
    }
}
