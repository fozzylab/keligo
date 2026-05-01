import WidgetKit
import SwiftUI

// MARK: - Shared data (reads from App Group UserDefaults)
// App Group ID: group.com.fozzylabs.keligo
// Set this up in Xcode → Signing & Capabilities → App Groups for BOTH targets

private let appGroupID = "group.com.fozzylabs.keligo"
private let sharedDefaults = UserDefaults(suiteName: appGroupID) ?? .standard

// MARK: - Timeline entry

struct KeligoEntry: TimelineEntry {
    let date: Date
    let category: String
    let letterCount: Int
    let streak: Int
    let hasPlayedToday: Bool
    let hasWonToday: Bool
}

// MARK: - Timeline provider

struct KeligoProvider: TimelineProvider {
    func placeholder(in context: Context) -> KeligoEntry {
        KeligoEntry(date: Date(), category: "Hayvanlar", letterCount: 6, streak: 3, hasPlayedToday: false, hasWonToday: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (KeligoEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KeligoEntry>) -> Void) {
        // Refresh at midnight
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 0
        components.minute = 1
        let nextMidnight = Calendar.current.date(from: components) ?? Date().addingTimeInterval(86400)

        completion(Timeline(entries: [entry()], policy: .after(nextMidnight)))
    }

    private func entry() -> KeligoEntry {
        let category = sharedDefaults.string(forKey: "widget_category") ?? "Kelime"
        let letterCount = sharedDefaults.integer(forKey: "widget_letterCount")
        let streak = sharedDefaults.integer(forKey: "currentStreak")
        let hasPlayed = sharedDefaults.bool(forKey: "widget_hasPlayedToday")
        let hasWon = sharedDefaults.bool(forKey: "widget_hasWonToday")
        return KeligoEntry(
            date: Date(),
            category: category,
            letterCount: letterCount > 0 ? letterCount : 6,
            streak: streak,
            hasPlayedToday: hasPlayed,
            hasWonToday: hasWon
        )
    }
}

// MARK: - Widget views

struct KeligoWidgetEntryView: View {
    var entry: KeligoEntry
    @Environment(\.widgetFamily) var family

    private let deepLinkURL = URL(string: "keligo://daily")!

    var body: some View {
        switch family {
        case .systemSmall:
            Link(destination: deepLinkURL) {
                smallView
            }
        case .systemMedium:
            Link(destination: deepLinkURL) {
                mediumView
            }
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        default:
            Link(destination: deepLinkURL) {
                smallView
            }
        }
    }

    // MARK: - Small widget

    private var smallView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.07, blue: 0.20), Color(red: 0.05, green: 0.15, blue: 0.30)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Text("⚰️").font(.system(size: 32))

                Text("Günlük Kelime")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white.opacity(0.7))

                // Letter dots
                HStack(spacing: 5) {
                    ForEach(0..<min(entry.letterCount, 8), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 10, height: 12)
                    }
                }

                Text(entry.category)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.white.opacity(0.15), in: Capsule())
                    .foregroundColor(.white)

                if entry.hasPlayedToday {
                    HStack(spacing: 4) {
                        Image(systemName: entry.hasWonToday ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(entry.hasWonToday
                                ? Color(red: 0.20, green: 0.95, blue: 0.45)
                                : Color(red: 1.00, green: 0.35, blue: 0.35))
                        Text(entry.hasWonToday ? "Kazandın!" : "Oynadın")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(entry.hasWonToday
                                ? Color(red: 0.20, green: 0.95, blue: 0.45)
                                : Color(red: 1.00, green: 0.35, blue: 0.35))
                    }
                } else if entry.streak > 1 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill").foregroundColor(.orange)
                        Text("\(entry.streak) seri")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                }
            }
            .padding(12)
        }
    }

    // MARK: - Medium widget

    private var mediumView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.07, blue: 0.20), Color(red: 0.10, green: 0.20, blue: 0.40)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                // Left: icon + streak
                VStack(spacing: 6) {
                    Text("⚰️").font(.system(size: 40))
                    if entry.streak > 1 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill").foregroundColor(.orange)
                            Text("\(entry.streak)")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                    }
                }
                .frame(width: 70)

                // Right: word hint
                VStack(alignment: .leading, spacing: 8) {
                    Text("Günlük Kelime")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(spacing: 5) {
                        ForEach(0..<min(entry.letterCount, 10), id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.85))
                                .frame(width: 12, height: 14)
                        }
                    }

                    HStack(spacing: 6) {
                        Text(entry.category)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.white.opacity(0.15), in: Capsule())
                            .foregroundColor(.white)

                        Spacer()

                        // Result icon or action
                        if entry.hasPlayedToday {
                            HStack(spacing: 4) {
                                Image(systemName: entry.hasWonToday
                                    ? "checkmark.circle.fill"
                                    : "xmark.circle.fill")
                                    .foregroundColor(entry.hasWonToday
                                        ? Color(red: 0.20, green: 0.95, blue: 0.45)
                                        : Color(red: 1.00, green: 0.35, blue: 0.35))
                                Text(entry.hasWonToday ? "Kazandın" : "Bitirdin")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(entry.hasWonToday
                                        ? Color(red: 0.20, green: 0.95, blue: 0.45)
                                        : Color(red: 1.00, green: 0.35, blue: 0.35))
                            }
                        } else {
                            Text("Oyna →")
                                .font(.caption.weight(.bold))
                                .foregroundColor(Color(red: 0.15, green: 0.85, blue: 1.00))
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
        }
    }

    // MARK: - Lock screen: Circular

    @ViewBuilder
    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                if entry.streak > 1 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("\(entry.streak)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                } else {
                    Text("⚰️")
                        .font(.system(size: 18))
                    Text("\(entry.letterCount)")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
            }
        }
    }

    // MARK: - Lock screen: Rectangular

    @ViewBuilder
    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "character.cursor.ibeam")
                    .font(.caption2.weight(.bold))
                Text("Günlük Kelime")
                    .font(.caption.weight(.bold))
            }
            Text("\(entry.letterCount) harf • \(entry.category)")
                .font(.caption2)
                .foregroundColor(.secondary)
            if entry.hasPlayedToday {
                HStack(spacing: 3) {
                    Image(systemName: entry.hasWonToday ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption2)
                    Text(entry.hasWonToday ? "Bugün kazandın!" : "Bugün oynadın")
                        .font(.caption2.weight(.semibold))
                }
            } else {
                Text("Dokunarak oyna →")
                    .font(.caption2.weight(.semibold))
            }
        }
        .widgetURL(URL(string: "keligo://daily")!)
    }
}

// MARK: - Widget configuration

struct KeligoWidget: Widget {
    let kind: String = "KeligoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KeligoProvider()) { entry in
            KeligoWidgetEntryView(entry: entry)
                .containerBackground(
                    LinearGradient(
                        colors: [Color(red: 0.03, green: 0.07, blue: 0.20), Color(red: 0.05, green: 0.15, blue: 0.30)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    for: .widget
                )
        }
        .configurationDisplayName("Keligo")
        .description("Günlük kelime ipucunu görün.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    KeligoWidget()
} timeline: {
    KeligoEntry(date: Date(), category: "Hayvanlar", letterCount: 7, streak: 5, hasPlayedToday: false, hasWonToday: false)
}

#Preview(as: .systemMedium) {
    KeligoWidget()
} timeline: {
    KeligoEntry(date: Date(), category: "Teknoloji", letterCount: 9, streak: 3, hasPlayedToday: true, hasWonToday: true)
}

#Preview(as: .accessoryCircular) {
    KeligoWidget()
} timeline: {
    KeligoEntry(date: Date(), category: "Hayvanlar", letterCount: 6, streak: 7, hasPlayedToday: false, hasWonToday: false)
}

#Preview(as: .accessoryRectangular) {
    KeligoWidget()
} timeline: {
    KeligoEntry(date: Date(), category: "Spor", letterCount: 5, streak: 2, hasPlayedToday: true, hasWonToday: false)
}
