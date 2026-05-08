import Foundation
import Combine

// MARK: - PiggyBankManager
//
// Kumbara mekaniği: Her kazanılan oyunda kumbara birikir.
// Kullanıcı reklamı izleyince birikmiş jetonları toplar.
// "Reklam izlemiyorum" hissini verir; aslında fark etmeden izliyor.

class PiggyBankManager: ObservableObject {
    static let shared = PiggyBankManager()

    // Her kazanılan oyunda ne kadar birikir
    static let earnPerWin   = 5
    // Kumbara dolduğunda tutulacak maksimum jeton
    static let maxBalance   = 200

    @Published var balance: Int {
        didSet { UserDefaults.standard.set(balance, forKey: "piggyBankBalance") }
    }

    private init() {
        balance = UserDefaults.standard.integer(forKey: "piggyBankBalance")
    }

    // MARK: - State

    /// Kumbara kaç jeton biriktirdi?
    var progress: Double { Double(balance) / Double(PiggyBankManager.maxBalance) }

    /// Kumbara tamamen doldu mu?
    var isFull: Bool { balance >= PiggyBankManager.maxBalance }

    /// Kumbara boş mu (gösterme)?
    var isEmpty: Bool { balance == 0 }

    // MARK: - Actions

    /// Her oyun kazanımında çağrılır.
    func earnOnWin() {
        guard balance < PiggyBankManager.maxBalance else { return }
        balance = min(balance + PiggyBankManager.earnPerWin, PiggyBankManager.maxBalance)
    }

    /// Rewarded reklam izlendikten sonra çağrılır — jetonları cüzdana aktarır.
    @discardableResult
    func collect() -> Int {
        let amount = balance
        guard amount > 0 else { return 0 }
        balance = 0
        JetonManager.shared.earn(amount)
        return amount
    }

    /// Kasa doluyken reklam izlenerek çağrılır — 2x jeton verir.
    @discardableResult
    func collectDouble() -> Int {
        let amount = balance * 2
        guard balance > 0 else { return 0 }
        balance = 0
        JetonManager.shared.earn(amount)
        return amount
    }
}
