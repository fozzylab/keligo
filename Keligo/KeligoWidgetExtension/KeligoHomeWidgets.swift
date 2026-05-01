// MARK: - KeligoHomeWidgets.swift
// Home Screen & Lock Screen widget'ları (Static, no user config)

import WidgetKit
import SwiftUI

// MARK: - App Group paylaşımlı UserDefaults

private let kAppGroupID = "group.com.fozzylabs.keligo"
private var sharedDefaults: UserDefaults { UserDefaults(suiteName: kAppGroupID) ?? .standard }

// MARK: - Timeline Entry

struct KeligoWidgetEntry: TimelineEntry {
    let date: Date
    let category: String
    let letterCount: Int
    let hasPlayedToday: Bool
    let hasWonToday: Bool
    let streak: Int
}

// MARK: - Timeline Provider

struct KeligoWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> KeligoWidgetEntry {
        KeligoWidgetEntry(date: .now, category: "Hayvanlar", letterCount: 7,
                           hasPlayedToday: false, hasWonToday: false, streak: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (KeligoWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KeligoWidgetEntry>) -> Void) {
        // Günlük sıfırlanma — bir sonraki gece yarısı + 1 dakika
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
            .addingTimeInterval(60)
        completion(Timeline(entries: [makeEntry()], policy: .after(midnight)))
    }

    private func makeEntry() -> KeligoWidgetEntry {
        KeligoWidgetEntry(
            date: .now,
            category:       sharedDefaults.string(forKey: "widget_category")      ?? "Günlük Kelime",
            letterCount:    sharedDefaults.integer(forKey: "widget_letterCount"),
            hasPlayedToday: sharedDefaults.bool(forKey: "widget_hasPlayedToday"),
            hasWonToday:    sharedDefaults.bool(forKey: "widget_hasWonToday"),
            streak:         sharedDefaults.integer(forKey: "widget_streak")
        )
    }
}

// MARK: - Entry View (router)

struct KeligoWidgetEntryView: View {
    var entry: KeligoWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:          smallView
        case .systemMedium:         mediumView
        case .accessoryCircular:    accessoryCircular
        case .accessoryRectangular: accessoryRectangular
        default:                    smallView
        }
    }

    // MARK: Small

    private var smallView: some View {
        ZStack {
            background
            VStack(spacing: 8) {
                Text("⚰️").font(.system(size: 30))

                if entry.hasPlayedToday {
                    Image(systemName: entry.hasWonToday ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(entry.hasWonToday
                            ? Color(red: 0.20, green: 0.95, blue: 0.45)
                            : Color(red: 1.00, green: 0.35, blue: 0.35))
                    Text(entry.hasWonToday ? "Kazandın!" : "Oynadın")
                        .font(.caption.weight(.bold))
                        .foregroundColor(entry.hasWonToday
                            ? Color(red: 0.20, green: 0.95, blue: 0.45)
                            : .white.opacity(0.7))
                } else {
                    // Letter blanks
                    let count = max(1, min(entry.letterCount, 9))
                    HStack(spacing: 4) {
                        ForEach(0..<count, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 10, height: 12)
                        }
                    }
                    Text(entry.category)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Color.white.opacity(0.18), in: Capsule())
                        .foregroundColor(.white)
                }

                if entry.streak > 1 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill").foregroundColor(.orange)
                        Text("\(entry.streak)")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                }
            }
            .padding(12)
        }
        .widgetURL(URL(string: "keligo://daily"))
    }

    // MARK: Medium

    private var mediumView: some View {
        ZStack {
            background
            HStack(spacing: 16) {
                // Sol: ikon + streak
                VStack(spacing: 6) {
                    Text("⚰️").font(.system(size: 42))
                    if entry.streak > 1 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill").foregroundColor(.orange)
                            Text("\(entry.streak)")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                    }
                }
                .frame(width: 72)

                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1)

                // Sağ: içerik
                VStack(alignment: .leading, spacing: 8) {
                    Text("Keligo")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.40))

                    if entry.hasPlayedToday {
                        Label(entry.hasWonToday ? "Bugün kazandın! 🎉" : "Bugün oynadın",
                              systemImage: entry.hasWonToday ? "trophy.fill" : "checkmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(entry.hasWonToday
                                ? Color(red: 0.20, green: 0.95, blue: 0.45)
                                : .white)
                        Text(entry.hasWonToday ? "Yarın yeni kelime gelecek." : "Yarın tekrar dene!")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.55))
                    } else {
                        Text("Günlük kelimeni tahmin et!")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white)
                        Text(entry.category)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.white.opacity(0.15), in: Capsule())
                            .foregroundColor(.white)
                        // Letter blanks
                        let count = max(1, min(entry.letterCount, 12))
                        HStack(spacing: 4) {
                            ForEach(0..<count, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.55))
                                    .frame(width: 11, height: 3)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding(16)
        }
        .widgetURL(URL(string: "keligo://daily"))
    }

    // MARK: Lock Screen — Circular

    @ViewBuilder
    private var accessoryCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                if entry.streak > 1 {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("\(entry.streak)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                } else if entry.hasPlayedToday {
                    Image(systemName: entry.hasWonToday ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 20))
                } else {
                    Text("⚰️").font(.system(size: 18))
                    Text("\(entry.letterCount)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                }
            }
        }
        .widgetURL(URL(string: "keligo://daily"))
    }

    // MARK: Lock Screen — Rectangular

    @ViewBuilder
    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "character.cursor.ibeam")
                    .font(.caption2.weight(.bold))
                Text("Günlük Kelime")
                    .font(.caption.weight(.bold))
            }
            if entry.hasPlayedToday {
                HStack(spacing: 3) {
                    Image(systemName: entry.hasWonToday ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption2)
                    Text(entry.hasWonToday ? "Kazandın! 🎉" : "Oynadın")
                        .font(.caption2.weight(.semibold))
                }
            } else {
                Text("\(entry.letterCount) harf • \(entry.category)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Oynamak için dokun →")
                    .font(.caption2.weight(.semibold))
            }
        }
        .widgetURL(URL(string: "keligo://daily"))
    }

    // MARK: Shared background

    private var background: some View {
        LinearGradient(
            colors: [Color(red: 0.04, green: 0.08, blue: 0.22),
                     Color(red: 0.10, green: 0.20, blue: 0.40)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - Small Widget

struct KeligoDailyWidget: Widget {
    let kind = "KeligoDailyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KeligoWidgetProvider()) { entry in
            KeligoWidgetEntryView(entry: entry)
                .containerBackground(
                    LinearGradient(
                        colors: [Color(red: 0.04, green: 0.08, blue: 0.22),
                                 Color(red: 0.10, green: 0.20, blue: 0.40)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    for: .widget
                )
        }
        .configurationDisplayName("Günlük Kelime")
        .description("Her gün yeni bir Türkçe kelime!")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Medium Widget

struct KeligoMediumWidget: Widget {
    let kind = "KeligoMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KeligoWidgetProvider()) { entry in
            KeligoWidgetEntryView(entry: entry)
                .containerBackground(
                    LinearGradient(
                        colors: [Color(red: 0.04, green: 0.08, blue: 0.22),
                                 Color(red: 0.10, green: 0.20, blue: 0.40)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    for: .widget
                )
        }
        .configurationDisplayName("Günlük Kelime (Geniş)")
        .description("Kategori ipucu ve seri bilgisi.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    KeligoDailyWidget()
} timeline: {
    KeligoWidgetEntry(date: .now, category: "Hayvanlar", letterCount: 7,
                       hasPlayedToday: false, hasWonToday: false, streak: 5)
    KeligoWidgetEntry(date: .now, category: "Teknoloji", letterCount: 9,
                       hasPlayedToday: true, hasWonToday: true, streak: 12)
}

#Preview(as: .systemMedium) {
    KeligoMediumWidget()
} timeline: {
    KeligoWidgetEntry(date: .now, category: "Spor", letterCount: 8,
                       hasPlayedToday: false, hasWonToday: false, streak: 3)
}

#Preview(as: .accessoryCircular) {
    KeligoDailyWidget()
} timeline: {
    KeligoWidgetEntry(date: .now, category: "Şehirler", letterCount: 6,
                       hasPlayedToday: false, hasWonToday: false, streak: 7)
}

#Preview(as: .accessoryRectangular) {
    KeligoDailyWidget()
} timeline: {
    KeligoWidgetEntry(date: .now, category: "Müzik", letterCount: 5,
                       hasPlayedToday: true, hasWonToday: false, streak: 2)
}
