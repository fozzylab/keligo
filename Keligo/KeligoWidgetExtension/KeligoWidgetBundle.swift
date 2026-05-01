// MARK: - KeligoWidgetBundle.swift
// Widget Extension — Tüm widget'lar tek bundle'da toplanır.
//
// ⚠️  XCODE KURULUM ADIMLARI (tek seferlik, ~5 dakika):
// ─────────────────────────────────────────────────────
// 1. Xcode → File → New → Target → "Widget Extension"
//    • Product Name: KeligoWidgetExtension
//    • Include Live Activity: ✓  (iOS 16.1+)
//    • Include Configuration App Intent: ✗
//    → Finish
//
// 2. Her iki target (Keligo + KeligoWidgetExtension) için:
//    Target → Signing & Capabilities → "+ Capability" → App Groups
//    → "group.com.fozzylabs.keligo" ekle (aynı ID her ikisinde)
//
// 3. Keligo target → Signing & Capabilities → "+ Capability" → Push Notifications
//    (Live Activity bildirim güncellemeleri için gerekli)
//
// 4. Keligo target → Info.plist → NSSupportsLiveActivities = YES  (Boolean)
//
// 5. Bu klasördeki TÜM .swift dosyalarını seç → sağ panel → Target Membership →
//    sadece "KeligoWidgetExtension" tikli olsun (Keligo'ya ekleme!)
//
// 6. LiveActivity.swift (Keligo klasöründe) →
//    Target Membership → HEM Keligo HEM KeligoWidgetExtension işaretle.
//    (DailyWordActivityAttributes her iki target'ta görünür olmalı)

import WidgetKit
import SwiftUI

// MARK: - Widget Bundle (@main entry point)

@main
struct KeligoWidgetBundle: WidgetBundle {
    var body: some Widget {
        KeligoDailyWidget()
        KeligoMediumWidget()
        if #available(iOS 16.1, *) {
            KeligoLiveActivityWidget()
        }
    }
}
