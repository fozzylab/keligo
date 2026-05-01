import SwiftUI

// MARK: - Word Report Sheet
// Shown from the game board when the user taps the flag (🚩) button.

struct WordReportSheet: View {
    let word: String
    let category: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: SettingsViewModel
    @State private var selected: String? = nil
    @State private var showConfirmation = false

    var t: AppTheme { settings.theme }

    private let reasons: [(emoji: String, text: String)] = [
        ("❌", "Kelime Türkçede yok"),
        ("✏️", "Yazım hatası var"),
        ("🗂️", "Yanlış kategoride"),
        ("😓", "Çok zor / uygunsuz"),
        ("💬", "Diğer"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()

                VStack(spacing: 20) {

                    // Word card
                    VStack(spacing: 6) {
                        Text(word)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(t.primaryText)
                            .tracking(4)
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill").font(.caption2)
                            Text(category).font(.caption.weight(.semibold))
                        }
                        .foregroundColor(t.accent)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(t.surface, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    Text("Bu kelimeyle ilgili ne sorun var?")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(t.secondaryText)

                    // Reason options
                    VStack(spacing: 10) {
                        ForEach(reasons, id: \.text) { reason in
                            Button {
                                selected = reason.text
                            } label: {
                                HStack(spacing: 12) {
                                    Text(reason.emoji).font(.title3)
                                    Text(reason.text)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(t.primaryText)
                                    Spacer()
                                    if selected == reason.text {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(t.accent)
                                    }
                                }
                                .padding(14)
                                .background(
                                    selected == reason.text
                                        ? AnyShapeStyle(t.accent.opacity(0.13))
                                        : AnyShapeStyle(t.surface),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selected == reason.text ? t.accent : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Submit button
                    Button {
                        guard let reason = selected else { return }
                        WordReportManager.shared.report(word: word, category: category, reason: reason)
                        withAnimation(.spring()) { showConfirmation = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { dismiss() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: showConfirmation ? "checkmark.circle.fill" : "flag.fill")
                            Text(showConfirmation ? "Bildirildi, teşekkürler!" : "Hata Bildir")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            selected == nil
                                ? AnyShapeStyle(Color.secondary.opacity(0.2))
                                : (showConfirmation
                                    ? AnyShapeStyle(Color.green.opacity(0.85))
                                    : AnyShapeStyle(Color.red.opacity(0.85))),
                            in: RoundedRectangle(cornerRadius: 18)
                        )
                        .foregroundColor(.white)
                        .animation(.easeInOut(duration: 0.2), value: showConfirmation)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(selected == nil || showConfirmation)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Hata Bildir 🚩")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(t.accentGradient)
                    }
                }
            }
        }
    }
}

// MARK: - Pending Reports List (shown in SettingsView)

struct PendingReportsView: View {
    @StateObject private var reporter = WordReportManager.shared
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showClearAlert = false

    var t: AppTheme { settings.theme }

    var body: some View {
        NavigationStack {
            ZStack {
                t.background.ignoresSafeArea()

                if reporter.reports.isEmpty {
                    VStack(spacing: 12) {
                        Text("✅").font(.system(size: 48))
                        Text("Bekleyen bildirim yok")
                            .font(.headline)
                            .foregroundColor(t.primaryText)
                        Text("Oyun içinde 🚩 butonuna basarak\nkelime hatalarını bildirebilirsin.")
                            .font(.subheadline)
                            .foregroundColor(t.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    List {
                        ForEach(reporter.reports) { report in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(report.word)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(t.primaryText)
                                    Spacer()
                                    Text(report.category)
                                        .font(.caption)
                                        .foregroundColor(t.accent)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(t.accent.opacity(0.12), in: Capsule())
                                }
                                Text(report.reason)
                                    .font(.caption)
                                    .foregroundColor(t.secondaryText)
                            }
                            .listRowBackground(t.surface)
                        }
                        .onDelete { reporter.delete(offsets: $0) }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Hata Bildirimleri (\(reporter.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") { dismiss() }.foregroundColor(t.accent)
                }
                if !reporter.reports.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                reporter.openMail()
                            } label: {
                                Label("Mail ile Gönder", systemImage: "envelope.fill")
                            }
                            Button(role: .destructive) {
                                showClearAlert = true
                            } label: {
                                Label("Tümünü Sil", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(t.accentGradient)
                        }
                    }
                }
            }
            .alert("Tümünü Sil", isPresented: $showClearAlert) {
                Button("Sil", role: .destructive) { reporter.clearAll() }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("Tüm bekleyen hata bildirimleri silinecek.")
            }
        }
    }
}
