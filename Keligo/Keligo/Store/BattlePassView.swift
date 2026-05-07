import SwiftUI

struct BattlePassView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var season: SeasonManager
    @EnvironmentObject var vip: VIPManager
    @Environment(\.dismiss) private var dismiss
    
    var t: AppTheme { settings.theme }
    
    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        seasonHeader
                        
                        // Progress bar
                        progressSection
                        
                        // Premium unlock CTA
                        if !season.isPremiumPass {
                            premiumCTA
                        }
                        
                        // Reward track
                        rewardTrack
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Sezonluk Ödüller")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(t.accent)
                }
            }
        }
    }
    
    private var seasonHeader: some View {
        VStack(spacing: 8) {
            Text(season.seasonName.uppercased())
                .font(.caption.weight(.black))
                .foregroundColor(t.secondaryText)
                .tracking(3)
            Text("Sezon \(season.seasonID)")
                .font(.title2.weight(.black))
                .foregroundColor(t.primaryText)
            Text("Oyna, XP kazan, ödülleri topla!")
                .font(.subheadline)
                .foregroundColor(t.secondaryText)
        }
        .padding(.vertical, 16)
    }
    
    private var progressSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Seviye \(season.currentTier)/\(season.maxTier)")
                    .font(.headline.weight(.bold))
                    .foregroundColor(t.primaryText)
                Spacer()
                Text("\(season.currentXP) XP")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(t.accent)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(t.surface)
                        .frame(height: 14)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(t.accentGradient)
                        .frame(width: geo.size.width * season.progressToNext, height: 14)
                        .animation(.easeInOut(duration: 0.5), value: season.progressToNext)
                }
            }
            .frame(height: 14)
        }
        .padding(16)
        .glassSurface(cornerRadius: 18, intensity: 0.7, borderGlow: t.accent, innerGlow: true)
    }
    
    private var premiumCTA: some View {
        Button {
            // Purchase premium pass — would trigger IAP
            season.unlockPremium()
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                    Text("Premium Sezon Passı")
                        .font(.headline.weight(.bold))
                }
                .foregroundColor(.white)
                Text("Tüm premium ödülleri aç + 2x Jeton kazancı")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.indigo.opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 18)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var rewardTrack: some View {
        VStack(spacing: 10) {
            ForEach(season.rewards) { reward in
                RewardTierRow(reward: reward, isUnlocked: season.currentTier >= reward.tier, isPremium: season.isPremiumPass, theme: t)
            }
        }
    }
}

struct RewardTierRow: View {
    let reward: SeasonReward
    let isUnlocked: Bool
    let isPremium: Bool
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Tier number
            ZStack {
                Circle()
                    .fill(isUnlocked ? theme.accent.opacity(0.2) : theme.surface)
                    .frame(width: 36, height: 36)
                Text("\(reward.tier)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(isUnlocked ? theme.accent : theme.secondaryText)
            }
            
            // Free reward
            HStack(spacing: 6) {
                Image(systemName: reward.freeRewardIcon)
                    .font(.caption)
                    .foregroundColor(isUnlocked ? theme.correct : theme.secondaryText)
                Text(reward.freeReward)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isUnlocked ? theme.primaryText : theme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isUnlocked ? theme.correct.opacity(0.08) : theme.surface.opacity(0.5))
            .cornerRadius(10)
            
            // Premium reward
            HStack(spacing: 6) {
                Image(systemName: reward.premiumRewardIcon)
                    .font(.caption)
                    .foregroundColor(isPremium && isUnlocked ? .yellow : theme.secondaryText.opacity(0.4))
                Text(reward.premiumReward)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isPremium && isUnlocked ? theme.primaryText : theme.secondaryText.opacity(0.4))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                (isPremium && isUnlocked)
                    ? Color.yellow.opacity(0.08)
                    : theme.surface.opacity(0.3)
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isPremium ? Color.yellow.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .padding(.vertical, 4)
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}
