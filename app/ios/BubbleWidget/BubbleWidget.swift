// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// iPhone home-screen widget: one soap bubble per waiting friend (colour and
// first letter only). It never knows what is inside a bubble.
// Needs a Widget Extension target named "BubbleWidget" with App Group
// "group.app.burumy.bubbles" on both the app and the extension (set up on a Mac).
import SwiftUI
import WidgetKit

struct BubbleItem: Decodable { let c: String; let l: String }

struct BubbleEntry: TimelineEntry {
    let date: Date
    let bubbles: [BubbleItem]
}

struct BubbleProvider: TimelineProvider {
    func read() -> [BubbleItem] {
        let d = UserDefaults(suiteName: "group.app.burumy.bubbles")
        guard let s = d?.string(forKey: "bubbles"), let data = s.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([BubbleItem].self, from: data)) ?? []
    }
    func placeholder(in context: Context) -> BubbleEntry { BubbleEntry(date: Date(), bubbles: []) }
    func getSnapshot(in context: Context, completion: @escaping (BubbleEntry) -> Void) {
        completion(BubbleEntry(date: Date(), bubbles: read()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<BubbleEntry>) -> Void) {
        completion(Timeline(entries: [BubbleEntry(date: Date(), bubbles: read())], policy: .never))
    }
}

extension Color {
    init(argbHex: String) {
        let v = UInt64(argbHex, radix: 16) ?? 0xFF8E8E93
        self.init(.sRGB, red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255, opacity: 1)
    }
}

struct SoapBubbleView: View {
    let color: Color
    let letter: String?
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [color.opacity(0.18), color.opacity(0.42), color.opacity(0.85)], center: .center, startRadius: 0, endRadius: 50))
            Circle().stroke(AngularGradient(colors: [color, Color(red: 0.5, green: 0.83, blue: 1), Color(red: 1, green: 0.7, blue: 0.9), color], center: .center), lineWidth: 2)
            GeometryReader { g in
                Ellipse().fill(Color.white.opacity(0.75))
                    .frame(width: g.size.width * 0.27, height: g.size.height * 0.16)
                    .position(x: g.size.width * 0.33, y: g.size.height * 0.29)
            }
            if let letter { Text(letter).font(.system(size: 18, weight: .semibold)).foregroundColor(.white).shadow(color: color, radius: 3) }
        }
    }
}

struct BubbleWidgetView: View {
    let entry: BubbleEntry
    let spots: [(CGFloat, CGFloat, CGFloat)] = [(0.30, 0.32, 0.44), (0.70, 0.28, 0.34), (0.55, 0.66, 0.40), (0.22, 0.74, 0.26), (0.84, 0.62, 0.24), (0.48, 0.12, 0.18)]
    var body: some View {
        GeometryReader { g in
            if entry.bubbles.isEmpty {
                SoapBubbleView(color: .gray, letter: nil).opacity(0.35).frame(width: g.size.width * 0.32, height: g.size.width * 0.32)
                    .position(x: g.size.width / 2, y: g.size.height / 2)
            } else {
                ForEach(Array(entry.bubbles.prefix(6).enumerated()), id: \.offset) { i, b in
                    let s = spots[i]
                    SoapBubbleView(color: Color(argbHex: b.c), letter: b.l)
                        .frame(width: g.size.width * s.2, height: g.size.width * s.2)
                        .position(x: g.size.width * s.0, y: g.size.height * s.1)
                }
            }
        }
        .widgetURL(URL(string: "burumy://bubbles"))
    }
}

@main
struct BubbleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BubbleWidget", provider: BubbleProvider()) { entry in
            if #available(iOS 17.0, *) {
                BubbleWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else {
                BubbleWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Burumy")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
