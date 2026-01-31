import SwiftUI

enum ColorTheme {
    // Background colors
    static let background = Color(red: 15/255, green: 23/255, blue: 42/255)        // #0f172a
    static let cardBg = Color(red: 30/255, green: 41/255, blue: 59/255)            // #1e293b
    static let surfaceBg = Color(red: 51/255, green: 65/255, blue: 85/255)         // #334155

    // Text colors
    static let textPrimary = Color(red: 241/255, green: 245/255, blue: 249/255)    // #f1f5f9
    static let textSecondary = Color(red: 148/255, green: 163/255, blue: 184/255)  // #94a3b8
    static let textMuted = Color(red: 100/255, green: 116/255, blue: 139/255)      // #64748b

    // Accent colors
    static let gold = Color(red: 245/255, green: 158/255, blue: 11/255)            // #f59e0b
    static let goldLight = Color(red: 251/255, green: 191/255, blue: 36/255)       // #fbbf24
    static let green = Color(red: 34/255, green: 197/255, blue: 94/255)            // #22c55e
    static let red = Color(red: 239/255, green: 68/255, blue: 68/255)              // #ef4444
    static let blue = Color(red: 59/255, green: 130/255, blue: 246/255)            // #3b82f6

    // Border
    static let border = Color(red: 51/255, green: 65/255, blue: 85/255)            // #334155

    // Holder badge colors (matching Electron app)
    static let holderColors: [(bg: Color, text: Color)] = [
        (Color(red: 30/255, green: 58/255, blue: 95/255), Color(red: 96/255, green: 165/255, blue: 250/255)),   // blue
        (Color(red: 63/255, green: 31/255, blue: 95/255), Color(red: 192/255, green: 132/255, blue: 252/255)),  // purple
        (Color(red: 31/255, green: 79/255, blue: 63/255), Color(red: 110/255, green: 231/255, blue: 183/255)),  // green
        (Color(red: 95/255, green: 63/255, blue: 31/255), Color(red: 251/255, green: 191/255, blue: 36/255)),   // amber
        (Color(red: 79/255, green: 31/255, blue: 31/255), Color(red: 252/255, green: 165/255, blue: 165/255)),  // red
    ]

    static func holderColor(for name: String, in holders: [String]) -> (bg: Color, text: Color) {
        let idx = holders.firstIndex(of: name) ?? 0
        return holderColors[idx % holderColors.count]
    }

    // Status colors
    static func statusColor(_ status: String) -> (bg: Color, text: Color) {
        switch status {
        case "Approved":
            return (Color(red: 22/255, green: 101/255, blue: 52/255), Color(red: 134/255, green: 239/255, blue: 172/255))
        case "Denied":
            return (Color(red: 127/255, green: 29/255, blue: 29/255), Color(red: 252/255, green: 165/255, blue: 165/255))
        case "Pending":
            return (Color(red: 124/255, green: 45/255, blue: 18/255), Color(red: 253/255, green: 186/255, blue: 116/255))
        default:
            return (surfaceBg, textSecondary)
        }
    }
}
