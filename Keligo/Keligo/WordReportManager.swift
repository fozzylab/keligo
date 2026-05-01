import Foundation
import SwiftUI
import Combine
import UIKit

// MARK: - Model

struct WordReport: Codable, Identifiable {
    var id = UUID()
    let word: String
    let category: String
    let reason: String
    let date: Date
}

// MARK: - Manager

class WordReportManager: ObservableObject {
    static let shared = WordReportManager()
    private let key = "pending_word_reports"

    @Published private(set) var reports: [WordReport] = []

    var count: Int { reports.count }

    private init() { load() }

    // MARK: - Public API

    func report(word: String, category: String, reason: String) {
        let r = WordReport(word: word, category: category, reason: reason, date: Date())
        reports.insert(r, at: 0)
        if reports.count > 100 { reports = Array(reports.prefix(100)) }
        save()
    }

    func delete(offsets: IndexSet) {
        reports.remove(atOffsets: offsets)
        save()
    }

    func clearAll() {
        reports = []
        save()
    }

    /// Opens the default mail app with pre-filled report content.
    func openMail() {
        guard !reports.isEmpty else { return }

        let lines = reports.map { r -> String in
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .none
            return "• \(r.word) [\(r.category)] → \(r.reason) (\(df.string(from: r.date)))"
        }.joined(separator: "\n")

        let subject = "Keligo – Kelime Hata Bildirimi"
        let body    = "Merhaba,\n\nAşağıdaki kelimeler için hata bildirimi yapıyorum:\n\n\(lines)\n\nTeşekkürler."

        var comps = URLComponents()
        comps.scheme = "mailto"
        comps.path   = "support@fozzylabs.com"
        comps.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body",    value: body)
        ]
        if let url = comps.url {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data    = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WordReport].self, from: data)
        else { return }
        reports = decoded
    }
}
