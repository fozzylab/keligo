import Foundation

enum Constants {
    static let appGroupID     = "group.com.fozzylabs.keligo"
    static let sharedDefaults = UserDefaults(suiteName: appGroupID) ?? .standard
}
