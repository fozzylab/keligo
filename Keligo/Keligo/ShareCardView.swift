import SwiftUI

// MARK: - Share card data

struct GameShareData {
    let modeName: String
    let word: String
    let category: String
    let wrongGuesses: Int
    let maxWrong: Int
    let won: Bool
    let streak: Int
    var dateString: String? = nil
}

// MARK: - Game share card (infinite / daily)

struct GameShareCard: View {
    let data: GameShareData

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.07, blue: 0.20),
                         Color(red: 0.08, green: 0.18, blue: 0.38)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 10) {
                    // Keligo mini logo — K harf kutusu
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.31, green: 0.56, blue: 0.97),
                                         Color(red: 0.00, green: 0.83, blue: 1.00)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                            .overlay(RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1))
                            .shadow(color: Color(red: 0.31, green: 0.56, blue: 0.97).opacity(0.5),
                                    radius: 6, y: 2)
                        Text("K")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KELIGO")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text(data.modeName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    Spacer()
                    if let date = data.dateString {
                        Text(date)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)

                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 1)

                // Result
                VStack(spacing: 10) {
                    Text(data.won ? "🎉 Kazandım!" : "💀 Kaybettim!")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text(data.word)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(data.won
                            ? Color(red: 0.20, green: 0.95, blue: 0.45)
                            : .yellow)
                        .tracking(2)

                    // Category
                    Text(data.category)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.white.opacity(0.12), in: Capsule())
                }
                .padding(.vertical, 16)

                // Attempt boxes
                HStack(spacing: 6) {
                    ForEach(0..<data.maxWrong, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(i < data.wrongGuesses
                                  ? Color(red: 0.95, green: 0.25, blue: 0.25).opacity(0.85)
                                  : Color(red: 0.18, green: 0.78, blue: 0.35).opacity(0.85))
                            .frame(width: 30, height: 30)
                    }
                }

                // Streak
                if data.streak > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").foregroundColor(.orange)
                        Text("\(data.streak) galibiyet serisi")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.80))
                    }
                    .padding(.top, 10)
                }

                Spacer()

                Text("#Keligo")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.30))
                    .padding(.bottom, 16)
            }
        }
        .frame(width: 360, height: 310)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Chapter share card

struct ChapterShareCard: View {
    let chapterTitle: String
    let chapterIcon: String
    let results: [Bool]
    let stars: Int

    private var wins: Int { results.filter { $0 }.count }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.14, green: 0.04, blue: 0.28),
                         Color(red: 0.30, green: 0.08, blue: 0.55)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    // Keligo mini logo — K harf kutusu
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.31, green: 0.56, blue: 0.97),
                                         Color(red: 0.00, green: 0.83, blue: 1.00)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 26, height: 26)
                            .shadow(color: Color(red: 0.31, green: 0.56, blue: 0.97).opacity(0.5), radius: 4)
                        Text("K")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Text("KELIGO")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Text("Bölüm Modu")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 12)

                Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1)

                VStack(spacing: 10) {
                    Text(chapterIcon).font(.system(size: 44))

                    Text(chapterTitle)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.system(size: 22))
                                .foregroundColor(i < stars ? .yellow : .white.opacity(0.20))
                        }
                    }

                    Text("\(wins)/\(results.count) doğru")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.70))

                    HStack(spacing: 6) {
                        ForEach(Array(results.enumerated()), id: \.offset) { _, won in
                            Image(systemName: won ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(won
                                    ? Color(red: 0.18, green: 0.78, blue: 0.35)
                                    : Color(red: 0.95, green: 0.25, blue: 0.25))
                        }
                    }
                }
                .padding(.vertical, 16)

                Spacer()

                Text("#Keligo")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.28))
                    .padding(.bottom, 16)
            }
        }
        .frame(width: 360, height: 330)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Image renderer helper

@MainActor
func renderShareImage<V: View>(_ view: V) -> UIImage? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 3.0
    return renderer.uiImage
}
