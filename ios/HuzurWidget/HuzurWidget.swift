import WidgetKit
import Foundation
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
        ("إِنَّ ٱللَّهَ مَعَنَا", "Allah bizimledir.", "Tevbe, 40"),
        ("كُلُّ نَفْسٍ ذَآئِقَةُ ٱلْمَوْتِ", "Her nefis ölümü tadacaktır.", "Âl-i İmrân, 185"),
        ("فَإِنِّى قَرِيبٌ", "Şüphesiz Ben çok yakınım.", "Bakara, 186"),
        ("لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ", "Şükrederseniz nimetimi artırırım.", "İbrâhîm, 7"),
        ("إِيَّاكَ نَعْبُدُ", "Yalnız Sana kulluk ederiz.", "Fâtiha, 5"),
        ("وَإِلَىٰ رَبِّكَ فَٱرْغَب", "Yalnızca Rabbine yönel.", "İnşirah, 8"),
        ("فَفِرُّوٓا۟ إِلَى ٱللَّهِ", "Öyleyse Allah'a koşun!", "Zâriyât, 50"),
        ("إِنَّ ٱللَّهَ يُحِبُّ ٱلْمُتَوَكِّلِينَ", "Allah tevekkül edenleri sever.", "Âl-i İmrân, 159"),
        ("إِنَّ ٱللَّهَ يُحِبُّ ٱلْمُحْسِنِينَ", "Allah iyilik edenleri sever.", "Bakara, 195"),
        ("ٱللَّهُ ٱلصَّمَدُ", "Her şey O'na muhtaçtır.", "İhlâs, 2"),
        ("وَرَحْمَتِى وَسِعَتْ كُلَّ شَىْءٍ", "Rahmetim her şeyi kuşatmıştır.", "A'râf, 156"),
        ("ٱللَّهُ لَطِيفٌۢ بِعِبَادِهِۦ", "Allah kullarına çok lütufkârdır.", "Şûrâ, 19"),
        ("وَكَفَىٰ بِٱللَّهِ وَكِيلًا", "Vekil olarak Allah yeter.", "Ahzâb, 3"),
        ("رَّبِّ زِدْنِى عِلْمًا", "Rabbim! İlmimi artır.", "Tâhâ, 114"),
        ("إِنَّ ٱللَّهَ غَفُورٌ رَّحِيمٌ", "Şüphesiz Allah çok bağışlayandır.", "Bakara, 173"),
        ("فَٱللَّهُ خَيْرٌ حَـٰفِظًا", "Allah en hayırlı koruyucudur.", "Yûsuf, 64"),
        ("وَلَا تَهِنُوا۟ وَلَا تَحْزَنُوا۟", "Gevşemeyin, asla hüzünlenmeyin.", "Âl-i İmrân, 139"),
        ("وَمَا تَوْفِيقِىٓ إِلَّا بِٱللَّهِ", "Başarım ancak Allah'ın yardımıyladır.", "Hûd, 88"),
        ("إِنَّا نَحْنُ نَزَّلْنَا ٱلذِّكْرَ", "Zikri biz indirdik.", "Hicr, 9"),
        ("وَإِنَّ ٱللَّهَ لَمَعَ ٱلْمُحْسِنِينَ", "Allah iyilik yapanlarla beraberdir.", "Ankebût, 69"),
        ("وَٱصْبِرْ عَلَىٰ مَآ أَصَابَكَ", "Başına gelene güzelce sabret.", "Lokmân, 17"),
        ("إِنَّمَا يُوَفَّى ٱلصَّـٰبِرُونَ أَجْرَهُم", "Sabredenlerin mükâfatı hesapsız verilir.", "Zümer, 10"),
        ("إِنَّمَا ٱلْمُؤْمِنُونَ إِخْوَةٌ", "Müminler ancak birbirinin kardeşidir.", "Hucurât, 10"),
        ("قَدْ أَفْلَحَ مَن تَزَكَّىٰ", "Arınan kimse kurtuluşa ermiştir.", "A'lâ, 14")
    ]

    private func entry(for date: Date, manualOffset: Int) -> HuzurVerseEntry {
        let hourSlot = Int(date.timeIntervalSince1970 / 3600.0)
        let rawIndex = (hourSlot + manualOffset) % verses.count
        let index = rawIndex < 0 ? rawIndex + verses.count : rawIndex
        let verse = verses[index]
        return HuzurVerseEntry(
            date: date,
            arabic: verse.ar,
            turkish: verse.tr,
            reference: verse.ref
        )
    }

    func placeholder(in context: Context) -> HuzurVerseEntry {
        let verse = verses[0]
        return HuzurVerseEntry(
            date: Date(),
            arabic: verse.ar,
            turkish: verse.tr,
            reference: verse.ref
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (HuzurVerseEntry) -> Void
    ) {
        let now = Date()
        let offset = UserDefaults(suiteName: "group.com.ilahi.tefekkur")?
            .integer(forKey: "hourly_manual_offset") ?? 0
        completion(entry(for: now, manualOffset: offset))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<HuzurVerseEntry>) -> Void
    ) {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        let offset = UserDefaults(suiteName: "group.com.ilahi.tefekkur")?
            .integer(forKey: "hourly_manual_offset") ?? 0

        var entries: [HuzurVerseEntry] = []
        entries.reserveCapacity(24)

        for step in 0..<24 {
            let date: Date
            if step == 0 {
                date = now
            } else {
                date = calendar.date(
                    byAdding: .hour,
                    value: step,
                    to: currentHour
                ) ?? now.addingTimeInterval(Double(step) * 3600)
            }
            entries.append(entry(for: date, manualOffset: offset))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
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
                        .lineLimit(family == .systemLarge ? 7 : (family == .systemMedium ? 5 : 3))
                        .minimumScaleFactor(0.50)
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
                            .lineLimit(family == .systemLarge ? 6 : (family == .systemMedium ? 3 : 1))
                            .minimumScaleFactor(0.50)
                            .fixedSize(horizontal: false, vertical: true)
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
                            .font(.system(size: family == .systemMedium ? 18 : 15, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.96, blue: 0.88))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .lineLimit(family == .systemLarge ? 4 : (family == .systemMedium ? 2 : 1))
                            .minimumScaleFactor(0.60)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(entry.turkish)
                        .font(.system(size: family == .systemLarge ? 13 : (family == .systemMedium ? 12 : 11), weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(family == .systemLarge ? 7 : (family == .systemMedium ? 4 : 2))
                        .minimumScaleFactor(0.60)
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
        .description("Özenle seçilmiş kısa ayetler; her saat otomatik değişir.")
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
        .description("Arapça metin ve kısa Türkçe meal içeren geniş saatlik ayet kartı.")
        .supportedFamilies([.systemMedium, .systemLarge, .systemSmall, .accessoryRectangular])
    }
}

@main
struct HuzurWidgetBundle: WidgetBundle {
    var body: some Widget {
        HuzurKisaAyetWidget()
        HuzurGenisAyetWidget()
    }
}
