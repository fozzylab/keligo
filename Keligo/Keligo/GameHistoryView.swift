import SwiftUI

struct GameHistoryView: View {
    @EnvironmentObject var stats: StatsManager
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var t: AppTheme { settings.theme }

    // Short date formatter: "3 Nis"
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("d MMM")
        f.locale = Locale(identifier: "tr_TR")
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()

                if stats.gameHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 52))
                            .foregroundStyle(t.accentGradient)
                        Text("Henüz oyun oynamadın")
                            .font(.headline)
                            .foregroundColor(t.primaryText)
                        Text("Oyunlar burada görünecek")
                            .font(.caption)
                            .foregroundColor(t.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(stats.gameHistory) { entry in
                                historyRow(entry)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Oyun Geçmişi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(t.accent)
                }
            }
        }
    }

    // MARK: - Row

    private func historyRow(_ entry: GameHistoryEntry) -> some View {
        HStack(spacing: 12) {
            // Result emoji
            Text(entry.won ? "✅" : "❌")
                .font(.title2)
                .frame(width: 36)

            // Middle: word + category/mode + error count
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.word)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(t.primaryText)
                    .lineLimit(1)

                Text("\(entry.category) · \(entry.mode)")
                    .font(.caption)
                    .foregroundColor(t.secondaryText)
                    .lineLimit(1)

                Text("\(entry.wrongCount)/\(entry.maxWrong) hata")
                    .font(.caption2)
                    .foregroundColor(entry.wrongCount == 0
                        ? t.correct
                        : entry.wrongCount >= entry.maxWrong ? t.wrong : t.secondaryText)
            }

            Spacer()

            // Date
            Text(dateFormatter.string(from: entry.date))
                .font(.caption)
                .foregroundColor(t.secondaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(t.surface, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    GameHistoryView()
        .environmentObject(StatsManager())
        .environmentObject(SettingsViewModel())
}
