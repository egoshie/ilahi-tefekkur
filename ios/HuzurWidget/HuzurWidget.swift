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
        ("أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ", "Kalpler Allahı anmakla huzur bulur.", "Rad, 28"),
        ("وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ ٱلْوَرِيدِ", "Biz ona şah damarından yakınız.", "Kâf, 16"),
        ("لَا تَقْنَطُوا۟ مِن رَّحْمَةِ ٱللَّهِ", "Allahın rahmetinden ümit kesmeyin.", "Zümer, 53"),
        ("وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ", "Rabbin sana verecek ve razı olacaksın.", "Duhâ, 5"),
        ("حَسْبُنَا ٱللَّهُ وَنِعْمَ ٱلْوَكِيلُ", "Allah bize yeter, O ne güzel vekildir.", "Âl-i İmrân, 173"),
        ("ٱدْعُونِىٓ أَسْتَجِبْ لَكُمْ", "Bana dua edin, size icabet edeyim.", "Mümin, 60"),
        ("فَإِنِّى قَرِيبٌ", "Şüphesiz Ben çok yakınım.", "Bakara, 186"),
        ("لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ", "Şükrederseniz nimetimi artırırım.", "İbrâhîm, 7"),
        ("وَمَن يَتَوَكَّلْ عَلَى ٱللَّهِ فَهُوَ حَسْبُهُۥ", "Allaha tevekkül edene O yeter.", "Talâk, 3"),
        ("إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", "Yalnız Sana kulluk ederiz.", "Fâtiha, 5"),
        ("وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ", "Nerede olursanız olun O sizinledir.", "Hadîd, 4"),
        ("لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا", "Allah kimseye gücünden fazlasını yüklemez.", "Bakara, 286"),
        ("وَإِلَىٰ رَبِّكَ فَٱرْغَب", "Yalnızca Rabbine yönel.", "İnşirah, 8")
    ]

    func placeholder(in context: Context) -> HuzurVerseEntry {
        HuzurVerseEntry(date: Date(), arabic: "مَا وَدَّعَكَ رَبُّكَ", turkish: "Rabbin seni terk etmedi.", reference: "Duhâ, 3")
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
            entries.append(HuzurVerseEntry(date: entryDate, arabic: item.ar, turkish: item.tr, reference: item.ref))
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
                    colors: [Color(red: 0.02, green: 0.07, blue: 0.12), Color(red: 0.04, green: 0.15, blue: 0.20)],
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
                        Text("HUZUR").font(.system(size: 8, weight: .bold))
                        Text(entry.reference).font(.system(size: 9, weight: .semibold)).multilineTextAlignment(.center)
                    }
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.arabic).font(.system(size: 13, weight: .bold)).lineLimit(1).minimumScaleFactor(0.75)
                    Text(entry.turkish).font(.system(size: 11.5, weight: .semibold)).lineLimit(3).minimumScaleFactor(0.65).fixedSize(horizontal: false, vertical: true)
                    Text("— " + entry.reference).font(.system(size: 9.5, weight: .medium)).opacity(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                VStack(alignment: .leading, spacing: 4) {
                    Text("Huzur").font(.system(size: 10, weight: .bold)).foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.51))
                    Text(entry.arabic).font(.system(size: 15, weight: .bold)).foregroundColor(Color(red: 1.0, green: 0.96, blue: 0.88)).frame(maxWidth: .infinity, alignment: .trailing)
                    Text(entry.turkish).font(.system(size: 12, weight: .semibold)).foregroundColor(.white).lineLimit(3).minimumScaleFactor(0.7)
                    Text("— " + entry.reference).font(.system(size: 10, weight: .medium)).foregroundColor(Color(red: 0.39, green: 1.0, blue: 0.85))
                }
            }
        }
        .applyGlassBackground()
    }
}

struct HuzurGenisAyetWidgetView: View {
    var entry: HuzurTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Günün İlhamı").font(.system(size: 11, weight: .bold)).foregroundColor(Color(red: 1.0, green: 0.88, blue: 0.51))
                Spacer()
                Text(entry.reference).font(.system(size: 10.5, weight: .bold)).foregroundColor(Color(red: 0.39, green: 1.0, blue: 0.85))
            }
            Spacer(minLength: 2)
            Text(entry.arabic).font(.system(size: family == .systemMedium ? 21 : 15, weight: .bold)).foregroundColor(Color(red: 1.0, green: 0.96, blue: 0.88)).frame(maxWidth: .infinity, alignment: .trailing).lineLimit(1).minimumScaleFactor(0.7)
            Text(entry.turkish).font(.system(size: family == .systemMedium ? 14 : 11.5, weight: .semibold)).foregroundColor(.white).lineLimit(3).minimumScaleFactor(0.65).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(family == .systemMedium ? 14 : 6)
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
        .description("Kilit ekranında kesilmeyen kompakt ayet kartı.")
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
        .description("Geniş kilit ekranı ve ana ekran ayet kartı.")
        .supportedFamilies([.systemMedium, .accessoryRectangular, .systemSmall])
    }
}

@main
struct HuzurWidgetBundle: WidgetBundle {
    var body: some Widget {
        HuzurKisaAyetWidget()
        HuzurGenisAyetWidget()
    }
}
