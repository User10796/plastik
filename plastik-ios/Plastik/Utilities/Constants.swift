import Foundation

enum Constants {
    static let appName = "Plastik"
    static let bundleID = "com.plastikapp.ios"
    static let cloudKitContainer = "iCloud.com.plastikapp.ios"
    static let appGroupID = "group.com.plastikapp.ios"
    static let feedURL = "https://user10796.github.io/plastik-data/cards.json"
    static let feedCacheKey = "cachedCardData"
    static let lastSyncKey = "lastSyncDate"
    static let feedRefreshInterval: TimeInterval = 86400 // 24 hours

    // App Group diagnostics and access
    static var appGroupContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static var sharedDefaults: UserDefaults? {
        // Debug: Print App Group diagnostics on first access
        struct DiagnosticOnce {
            static let run: Void = {
                print("=== App Group Diagnostics ===")
                print("App Group ID: \(Constants.appGroupID)")
                if let url = Constants.appGroupContainerURL {
                    print("Container URL: \(url.path)")
                    print("Container exists: \(FileManager.default.fileExists(atPath: url.path))")
                } else {
                    print("Container URL: nil - App Group not available")
                    print("Possible causes:")
                    print("  1. App Group not created in Developer Portal")
                    print("  2. App Group not added to App ID in Developer Portal")
                    print("  3. App Group not checked in Xcode Signing & Capabilities")
                    print("  4. Provisioning profile needs refresh")
                }
                print("=============================")
            }()
        }
        _ = DiagnosticOnce.run

        guard appGroupContainerURL != nil else { return nil }
        return UserDefaults(suiteName: appGroupID)
    }
}
