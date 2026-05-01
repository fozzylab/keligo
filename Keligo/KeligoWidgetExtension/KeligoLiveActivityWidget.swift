// MARK: - KeligoLiveActivityWidget.swift
// Live Activity UI — Dynamic Island (compact/expanded) + Lock Screen banner
// iOS 16.1+ gerektirir.
//
// NOT: DailyWordActivityAttributes Keligo/LiveActivity.swift dosyasında tanımlı.
// O dosyanın Target Membership'inde KeligoWidgetExtension de işaretli olmalı!

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget

@available(iOS 16.1, *)
struct KeligoLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DailyWordActivityAttributes.self) { context in
            // MARK: Lock Screen / Notification banner
            lockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.04, green: 0.08, blue: 0.22))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: Dynamic Island — Expanded
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Text("⚰️").font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Keligo")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white.opacity(0.55))
                            Text(context.attributes.dateLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    wrongIndicator(context: context)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.center) {
                    maskedWordView(context: context)
                        .padding(.horizontal, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    bottomBar(context: context)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }

            } compactLeading: {
                // MARK: Dynamic Island — Compact leading
                Text("⚰️").font(.system(size: 14))

            } compactTrailing: {
                // MARK: Dynamic Island — Compact trailing
                if context.state.status == "won" {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.20, green: 0.95, blue: 0.45))
                } else if context.state.status == "lost" {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(red: 1.00, green: 0.35, blue: 0.35))
                } else {
                    // Wrong remaining as small pill
                    Text("\(context.state.wrongRemaining)")
                        .font(.caption.weight(.black))
                        .foregroundColor(wrongColor(context.state.wrongRemaining, max: context.state.maxWrong))
                }

            } minimal: {
                // MARK: Dynamic Island — Minimal (smallest)
                if context.state.status == "won" {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(red: 0.20, green: 0.95, blue: 0.45))
                } else {
                    Text("⚰️").font(.system(size: 12))
                }
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<DailyWordActivityAttributes>) -> some View {
        HStack(spacing: 14) {
            // Left: keligo icon + status
            VStack(spacing: 4) {
                Text("⚰️").font(.system(size: 30))
                statusBadge(context.state.status)
            }
            .frame(width: 52)

            // Center: masked word + category
            VStack(alignment: .leading, spacing: 6) {
                Text(context.state.category)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.60))

                maskedWordView(context: context)

                // Progress bar
                progressBar(
                    revealed: context.state.revealedLetters,
                    total: context.state.totalLetters
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: wrong count
            wrongIndicator(context: context)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func maskedWordView(context: ActivityViewContext<DailyWordActivityAttributes>) -> some View {
        Text(context.state.maskedWord
            .map { $0 == "_" ? "＿" : String($0) }
            .joined(separator: " "))
            .font(.system(size: 16, weight: .black, design: .monospaced))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    @ViewBuilder
    private func wrongIndicator(context: ActivityViewContext<DailyWordActivityAttributes>) -> some View {
        VStack(spacing: 2) {
            Text("\(context.state.wrongRemaining)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(wrongColor(context.state.wrongRemaining, max: context.state.maxWrong))
            Text("kalan hak")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.50))
        }
    }

    @ViewBuilder
    private func bottomBar(context: ActivityViewContext<DailyWordActivityAttributes>) -> some View {
        HStack {
            Text(context.attributes.dateLabel)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.55))
            Spacer()
            let pct = context.state.totalLetters > 0
                ? Double(context.state.revealedLetters) / Double(context.state.totalLetters)
                : 0
            Text("%\(Int(pct * 100)) çözüldü")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.70))
        }
    }

    @ViewBuilder
    private func progressBar(revealed: Int, total: Int) -> some View {
        let pct = total > 0 ? Double(revealed) / Double(total) : 0
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.18))
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.20, green: 0.95, blue: 0.45))
                    .frame(width: geo.size.width * pct)
            }
        }
        .frame(height: 4)
    }

    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        switch status {
        case "won":
            Label("Kazandın", systemImage: "checkmark.circle.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(red: 0.20, green: 0.95, blue: 0.45))
                .labelStyle(.iconOnly)
                .font(.title3)
        case "lost":
            Label("Kaybettin", systemImage: "xmark.circle.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(red: 1.00, green: 0.35, blue: 0.35))
                .labelStyle(.iconOnly)
                .font(.title3)
        default:
            EmptyView()
        }
    }

    // MARK: - Helpers

    private func wrongColor(_ remaining: Int, max: Int) -> Color {
        let ratio = max > 0 ? Double(remaining) / Double(max) : 1
        if ratio > 0.60 { return Color(red: 0.20, green: 0.95, blue: 0.45) }
        if ratio > 0.30 { return .orange }
        return Color(red: 1.00, green: 0.35, blue: 0.35)
    }
}

// MARK: - Preview

@available(iOS 16.1, *)
#Preview("Lock Screen", as: .content, using: DailyWordActivityAttributes(
    startedAt: .now,
    dateLabel: "26 Nisan"
)) {
    KeligoLiveActivityWidget()
} contentStates: {
    DailyWordActivityAttributes.State(
        maskedWord: "H_Y_AN", category: "Hayvanlar",
        revealedLetters: 3, totalLetters: 6,
        wrongRemaining: 4, maxWrong: 6,
        status: "playing"
    )
    DailyWordActivityAttributes.State(
        maskedWord: "HAYVAN", category: "Hayvanlar",
        revealedLetters: 6, totalLetters: 6,
        wrongRemaining: 3, maxWrong: 6,
        status: "won"
    )
}
