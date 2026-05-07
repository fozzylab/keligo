import Foundation
import SwiftUI
import UIKit

// MARK: - Manager (kalıcı saklama yok — direkt mail gönderir)

class WordReportManager {
    static let shared = WordReportManager()
    private init() {}

    /// Sadece bu kelimeyi içeren mail uygulamasını açar. Hiçbir şey saklanmaz.
    func sendDirectMail(word: String, category: String, reason: String) {
        let subject = "Keligo – Kelime Hata Bildirimi"
        let body = """
        Merhaba,

        Aşağıdaki kelime için hata bildirimi yapıyorum:

        • Kelime   : \(word)
        • Kategori : \(category)
        • Sebep    : \(reason)

        Teşekkürler.
        """

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
}
