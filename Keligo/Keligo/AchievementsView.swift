import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var achievements: AchievementManager
    @Environment(\.dismiss) private var dismiss

    var t: AppTheme { settings.theme }
    private var unlockedCount: Int { achievements.achievements.filter { $0.isUnlocked }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Progress summary
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(unlockedCount)/\(achievements.achievements.count)")
                                    .font(.largeTitle.bold()).foregroundColor(t.primaryText)
                                Text("başarım açıldı")
                                    .font(.subheadline).foregroundColor(t.secondaryText)
                            }
                            Spacer()
                            ZStack {
                                Circle().stroke(t.surface, lineWidth: 8).frame(width: 70, height: 70)
                                Circle()
                                    .trim(from: 0, to: CGFloat(unlockedCount) / CGFloat(achievements.achievements.count))
                                    .stroke(t.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: 70, height: 70)
                                    .rotationEffect(.degrees(-90))
                                Text("\(Int(Double(unlockedCount) / Double(achievements.achievements.count) * 100))%")
                                    .font(.caption.bold()).foregroundColor(t.primaryText)
                            }
                        }
                        .padding(16).background(t.surface).cornerRadius(14)
                        .padding(.horizontal)

                        // Achievement list
                        ForEach(achievements.achievements) { achievement in
                            AchievementRow(achievement: achievement, theme: t)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Başarımlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }.foregroundColor(t.accent)
                }
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 14) {
            Text(achievement.isUnlocked ? achievement.icon : "🔒")
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(achievement.isUnlocked ? theme.accent.opacity(0.15) : theme.surface)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(achievement.isUnlocked ? theme.primaryText : theme.secondaryText)
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(theme.correct)
            }
        }
        .padding(12)
        .background(theme.surface)
        .cornerRadius(12)
        .opacity(achievement.isUnlocked ? 1 : 0.6)
    }
}

#Preview {
    AchievementsView()
        .environmentObject(SettingsViewModel())
        .environmentObject(AchievementManager.shared)
}
