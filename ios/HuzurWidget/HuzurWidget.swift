import WidgetKit
import SwiftUI

private let huzurAppGroup = "group.com.ilahi.tefekkur"

struct HuzurVerseEntry: TimelineEntry {
    let date: Date
    let arabic: String
    let turkish: String
    let reference: String
}

struct HuzurTimelineProvider: TimelineProvider {
    func savedEntry(at date: Date) -> HuzurVerseEntry {
        let defaults = UserDefaults(suiteName: huzurAppGroup)
        let arabic = defaults?.string(forKey: "huzur_widget_arabic") ?? "مَا وَدَّعَكَ رَبُّكَ"
        let turkish = defaults?.string(forKey: "huzur_widget_turkish") ?? "Rabbin seni terk etmedi."
        let reference = defaults?.string(forKey: "huzur_widget_reference") ?? "Duhâ, 3"
        return HuzurVerseEntry(date: date, arabic: arabic, turkish: turkish, reference: reference)
    }

    func placeholder(in context: Context) -> HuzurVerseEntry {
        savedEntry(at: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (HuzurVerseEntry) -> Void) {
        completion(savedEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HuzurVerseEntry>) -> Void) {
        let entry = savedEntry(at: Date())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 60, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

extension View {
    @ViewBuilder
    func huzurWidgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(for: .widget) {
                LinearGradient(
                    colors: [Color(red: 0.015, green: 0.055, blue: 0.09), Color(red: 0.025, green: 0.13, blue: 0.16)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            self.background(Color(red: 0.015, green: 0.055, blue: 0.09))
        }
    }
}

struct HuzurCompactWidgetView: View {
    let entry: HuzurVerseEntry
    @Environment(\.widgetFamily) private var family

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
                        Text(entry.reference).font(.system(size: 8, weight: .semibold)).multilineTextAlignment(.center)
                    }
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.arabic).font(.system(size: 13, weight: .bold)).lineLimit(1).minimumScaleFactor(0.65)
                    Text(entry.turkish).font(.system(size: 11, weight: .semibold)).lineLimit(2).minimumScaleFactor(0.7)
                    Text("— " + entry.reference).font(.system(size: 9, weight: .medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                VStack(alignment: .leading, spacing: 5) {
                    Text("Huzur").font(.system(size: 10, weight: .bold)).foregroundColor(Color(red: 1, green: 0.88, blue: 0.51))
                    Text(entry.arabic).font(.system(size: 15, weight: .bold)).frame(maxWidth: .infinity, alignment: .trailing).lineLimit(1)
                    Text(entry.turkish).font(.system(size: 12, weight: .semibold)).lineLimit(2)
                    Text("— " + entry.reference).font(.system(size: 10, weight: .medium)).foregroundColor(Color(red: 0.39, green: 1, blue: 0.85))
                }
            }
        }
        .foregroundColor(.white)
        .huzurWidgetBackground()
    }
}

struct HuzurWideWidgetView: View {
    let entry: HuzurVerseEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Günün İlhamı").font(.system(size: 11, weight: .bold)).foregroundColor(Color(red: 1, green: 0.88, blue: 0.51))
                Spacer()
                Text(entry.reference).font(.system(size: 10, weight: .bold)).foregroundColor(Color(red: 0.39, green: 1, blue: 0.85))
            }
            Spacer(minLength: 2)
            Text(entry.arabic).font(.system(size: family == .systemMedium ? 21 : 16, weight: .bold)).foregroundColor(Color(red: 1, green: 0.96, blue: 0.88)).frame(maxWidth: .infinity, alignment: .trailing).lineLimit(1).minimumScaleFactor(0.65)
            Text("“" + entry.turkish + "”").font(.system(size: family == .systemMedium ? 14 : 12, weight: .semibold)).foregroundColor(.white).lineLimit(3)
        }
        .padding(family == .systemMedium ? 16 : 10)
        .huzurWidgetBackground()
    }
}

struct HuzurCompactWidget: Widget {
    let kind = "HuzurCompactWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HuzurTimelineProvider()) { entry in
            HuzurCompactWidgetView(entry: entry)
        }
        .configurationDisplayName("Huzur • Saatlik Ayet")
        .description("Kilit ekranında kısa ayet ve kaynak bilgisi.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular, .systemSmall])
    }
}

struct HuzurWideWidget: Widget {
    let kind = "HuzurWideWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HuzurTimelineProvider()) { entry in
            HuzurWideWidgetView(entry: entry)
        }
        .configurationDisplayName("Huzur • Geniş İlham Kartı")
        .description("Ana ekranda geniş ayet kartı.")
        .supportedFamilies([.systemMedium, .systemLarge, .systemSmall])
    }
}

@main
struct HuzurWidgetBundle: WidgetBundle {
    var body: some Widget {
        HuzurCompactWidget()
        HuzurWideWidget()
    }
}
