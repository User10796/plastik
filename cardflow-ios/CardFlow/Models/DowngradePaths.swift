import Foundation

enum DowngradePaths {
    static let paths: [String: [String]] = [
        "Chase Sapphire Preferred": ["Freedom Unlimited", "Freedom Flex", "Freedom"],
        "Chase Sapphire Reserve": ["Freedom Unlimited", "Freedom Flex", "Freedom", "Sapphire Preferred"],
        "Chase United Quest": ["United Gateway (no AF)"],
        "Chase United Explorer": ["United Gateway (no AF)"],
        "Chase Southwest Priority": ["Southwest Plus"],
        "Amex Gold": ["Amex Green (lower AF)", "None - keep or cancel"],
        "Amex Platinum": ["Amex Gold", "Amex Green", "None - keep or cancel"],
        "Amex Blue Cash Preferred": ["Blue Cash Everyday (no AF)"],
        "Amex Delta Platinum": ["Delta Blue (no AF)"],
        "Citi Premier": ["Citi Double Cash", "Citi Custom Cash"],
        "Capital One Venture X": ["Venture", "VentureOne"],
        "Capital One Venture": ["VentureOne (no AF)"]
    ]

    static func options(for cardName: String) -> [String] {
        // Try exact match first, then partial match
        if let exact = paths[cardName] { return exact }
        for (key, value) in paths {
            if cardName.localizedCaseInsensitiveContains(key) || key.localizedCaseInsensitiveContains(cardName) {
                return value
            }
        }
        return []
    }
}
