import SwiftUI

// MARK: - Design System
// Based on Plastik UI Design Specifications

// MARK: - Spacing (8px Grid)

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
}

// MARK: - Card Sizes

enum CardSize {
    case micro      // 32 × 20px - Inline references
    case small      // 64 × 40px - List rows, badges
    case medium     // 160 × 100px - Dashboard, grids
    case large      // Full width × 180px - Card detail header
    case extraLarge // 320 × 200px - Promotional

    var size: CGSize {
        switch self {
        case .micro: return CGSize(width: 32, height: 20)
        case .small: return CGSize(width: 64, height: 40)
        case .medium: return CGSize(width: 160, height: 100)
        case .large: return CGSize(width: 320, height: 180)
        case .extraLarge: return CGSize(width: 320, height: 200)
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .micro: return 4
        case .small: return 6
        case .medium: return 12
        case .large, .extraLarge: return 16
        }
    }
}

// MARK: - Issuer Colors & Gradients

struct IssuerTheme {
    let primaryColor: Color
    let secondaryColor: Color
    let gradient: LinearGradient
    let logoColor: Color

    var colors: [Color] {
        [primaryColor, secondaryColor]
    }
}

enum IssuerGradients {
    // Chase
    static let chaseSapphire = IssuerTheme(
        primaryColor: Color(hex: "004879"),
        secondaryColor: Color(hex: "1a6bb3"),
        gradient: LinearGradient(colors: [Color(hex: "004879"), Color(hex: "1a6bb3")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let chaseFreedom = IssuerTheme(
        primaryColor: Color(hex: "2c3e50"),
        secondaryColor: Color(hex: "4a6074"),
        gradient: LinearGradient(colors: [Color(hex: "2c3e50"), Color(hex: "4a6074")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let chaseInk = IssuerTheme(
        primaryColor: Color(hex: "1a1a2e"),
        secondaryColor: Color(hex: "16213e"),
        gradient: LinearGradient(colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    // American Express
    static let amexBlue = IssuerTheme(
        primaryColor: Color(hex: "006FCF"),
        secondaryColor: Color(hex: "00A1E4"),
        gradient: LinearGradient(colors: [Color(hex: "006FCF"), Color(hex: "00A1E4")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let amexGold = IssuerTheme(
        primaryColor: Color(hex: "B4975A"),
        secondaryColor: Color(hex: "CFB53B"),
        gradient: LinearGradient(colors: [Color(hex: "B4975A"), Color(hex: "CFB53B")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let amexPlatinum = IssuerTheme(
        primaryColor: Color(hex: "A9A9A9"),
        secondaryColor: Color(hex: "E8E8E8"),
        gradient: LinearGradient(colors: [Color(hex: "A9A9A9"), Color(hex: "E8E8E8")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: Color(hex: "333333")
    )

    static let amexGreen = IssuerTheme(
        primaryColor: Color(hex: "1B5E3C"),
        secondaryColor: Color(hex: "2E8B57"),
        gradient: LinearGradient(colors: [Color(hex: "1B5E3C"), Color(hex: "2E8B57")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    // Capital One
    static let capitalOneVenture = IssuerTheme(
        primaryColor: Color(hex: "D03027"),
        secondaryColor: Color(hex: "a02620"),
        gradient: LinearGradient(colors: [Color(hex: "D03027"), Color(hex: "a02620")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let capitalOneVentureX = IssuerTheme(
        primaryColor: Color(hex: "1a1a1a"),
        secondaryColor: Color(hex: "333333"),
        gradient: LinearGradient(colors: [Color(hex: "1a1a1a"), Color(hex: "333333")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let capitalOneQuicksilver = IssuerTheme(
        primaryColor: Color(hex: "004977"),
        secondaryColor: Color(hex: "00325a"),
        gradient: LinearGradient(colors: [Color(hex: "004977"), Color(hex: "00325a")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    // Citi
    static let citiPremier = IssuerTheme(
        primaryColor: Color(hex: "003B70"),
        secondaryColor: Color(hex: "0066b2"),
        gradient: LinearGradient(colors: [Color(hex: "003B70"), Color(hex: "0066b2")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let citiDoubleCash = IssuerTheme(
        primaryColor: Color(hex: "2F4F4F"),
        secondaryColor: Color(hex: "4a6b6b"),
        gradient: LinearGradient(colors: [Color(hex: "2F4F4F"), Color(hex: "4a6b6b")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    // Discover
    static let discoverIt = IssuerTheme(
        primaryColor: Color(hex: "FF6600"),
        secondaryColor: Color(hex: "ff8533"),
        gradient: LinearGradient(colors: [Color(hex: "FF6600"), Color(hex: "ff8533")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    // Other Issuers
    static let bankOfAmerica = IssuerTheme(
        primaryColor: Color(hex: "E31837"),
        secondaryColor: Color(hex: "a31228"),
        gradient: LinearGradient(colors: [Color(hex: "E31837"), Color(hex: "a31228")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let wellsFargo = IssuerTheme(
        primaryColor: Color(hex: "CD1409"),
        secondaryColor: Color(hex: "9a0f07"),
        gradient: LinearGradient(colors: [Color(hex: "CD1409"), Color(hex: "9a0f07")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let usBank = IssuerTheme(
        primaryColor: Color(hex: "D71E28"),
        secondaryColor: Color(hex: "a3171e"),
        gradient: LinearGradient(colors: [Color(hex: "D71E28"), Color(hex: "a3171e")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let barclays = IssuerTheme(
        primaryColor: Color(hex: "00AEEF"),
        secondaryColor: Color(hex: "0088cc"),
        gradient: LinearGradient(colors: [Color(hex: "00AEEF"), Color(hex: "0088cc")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    // Tier 2 Issuers
    static let usaa = IssuerTheme(
        primaryColor: Color(hex: "002F6C"),
        secondaryColor: Color(hex: "004a9f"),
        gradient: LinearGradient(colors: [Color(hex: "002F6C"), Color(hex: "004a9f")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let navyFederal = IssuerTheme(
        primaryColor: Color(hex: "003366"),
        secondaryColor: Color(hex: "004d99"),
        gradient: LinearGradient(colors: [Color(hex: "003366"), Color(hex: "004d99")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let pnc = IssuerTheme(
        primaryColor: Color(hex: "F58025"),
        secondaryColor: Color(hex: "c66620"),
        gradient: LinearGradient(colors: [Color(hex: "F58025"), Color(hex: "c66620")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let tdBank = IssuerTheme(
        primaryColor: Color(hex: "34A853"),
        secondaryColor: Color(hex: "2a8a44"),
        gradient: LinearGradient(colors: [Color(hex: "34A853"), Color(hex: "2a8a44")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let synchrony = IssuerTheme(
        primaryColor: Color(hex: "3D4ED4"),
        secondaryColor: Color(hex: "313eb0"),
        gradient: LinearGradient(colors: [Color(hex: "3D4ED4"), Color(hex: "313eb0")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let breadFinancial = IssuerTheme(
        primaryColor: Color(hex: "E94E1B"),
        secondaryColor: Color(hex: "ba3f16"),
        gradient: LinearGradient(colors: [Color(hex: "E94E1B"), Color(hex: "ba3f16")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let goldmanSachs = IssuerTheme(
        primaryColor: Color(hex: "7399C6"),
        secondaryColor: Color(hex: "5c7ba0"),
        gradient: LinearGradient(colors: [Color(hex: "7399C6"), Color(hex: "5c7ba0")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let fnbo = IssuerTheme(
        primaryColor: Color(hex: "004B8D"),
        secondaryColor: Color(hex: "003a6d"),
        gradient: LinearGradient(colors: [Color(hex: "004B8D"), Color(hex: "003a6d")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let creditOne = IssuerTheme(
        primaryColor: Color(hex: "0068B3"),
        secondaryColor: Color(hex: "005390"),
        gradient: LinearGradient(colors: [Color(hex: "0068B3"), Color(hex: "005390")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let upgrade = IssuerTheme(
        primaryColor: Color(hex: "00BFA5"),
        secondaryColor: Color(hex: "009984"),
        gradient: LinearGradient(colors: [Color(hex: "00BFA5"), Color(hex: "009984")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let avant = IssuerTheme(
        primaryColor: Color(hex: "7B68EE"),
        secondaryColor: Color(hex: "6253c0"),
        gradient: LinearGradient(colors: [Color(hex: "7B68EE"), Color(hex: "6253c0")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    // Tier 3 - Tech/Fintech
    static let appleCard = IssuerTheme(
        primaryColor: Color(hex: "F5F5F7"),
        secondaryColor: Color(hex: "E8E8E8"),
        gradient: LinearGradient(colors: [Color(hex: "F5F5F7"), Color(hex: "E8E8E8")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: Color(hex: "1D1D1F")
    )

    static let brex = IssuerTheme(
        primaryColor: Color(hex: "FF5C35"),
        secondaryColor: Color(hex: "cc4a2a"),
        gradient: LinearGradient(colors: [Color(hex: "FF5C35"), Color(hex: "cc4a2a")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let ramp = IssuerTheme(
        primaryColor: Color(hex: "26C485"),
        secondaryColor: Color(hex: "1e9d6a"),
        gradient: LinearGradient(colors: [Color(hex: "26C485"), Color(hex: "1e9d6a")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    static let mercury = IssuerTheme(
        primaryColor: Color(hex: "5851DB"),
        secondaryColor: Color(hex: "4641af"),
        gradient: LinearGradient(colors: [Color(hex: "5851DB"), Color(hex: "4641af")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    // Custom Card
    static let customCard = IssuerTheme(
        primaryColor: Color(hex: "6B7280"),
        secondaryColor: Color(hex: "4B5563"),
        gradient: LinearGradient(colors: [Color(hex: "6B7280"), Color(hex: "4B5563")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    // Generic/Unknown
    static let unknown = IssuerTheme(
        primaryColor: Color(hex: "4a5568"),
        secondaryColor: Color(hex: "2d3748"),
        gradient: LinearGradient(colors: [Color(hex: "4a5568"), Color(hex: "2d3748")], startPoint: .topLeading, endPoint: .bottomTrailing),
        logoColor: .white
    )

    // Get theme for issuer
    static func theme(for issuer: Issuer, cardName: String = "") -> IssuerTheme {
        let nameLower = cardName.lowercased()

        switch issuer {
        // Tier 1 - Major Issuers
        case .chase:
            if nameLower.contains("sapphire") {
                return chaseSapphire
            } else if nameLower.contains("ink") {
                return chaseInk
            } else {
                return chaseFreedom
            }
        case .amex:
            if nameLower.contains("gold") {
                return amexGold
            } else if nameLower.contains("platinum") || nameLower.contains("centurion") {
                return amexPlatinum
            } else if nameLower.contains("green") {
                return amexGreen
            } else {
                return amexBlue
            }
        case .citi:
            if nameLower.contains("double cash") {
                return citiDoubleCash
            } else {
                return citiPremier
            }
        case .capitalOne:
            if nameLower.contains("venture x") {
                return capitalOneVentureX
            } else if nameLower.contains("quicksilver") {
                return capitalOneQuicksilver
            } else {
                return capitalOneVenture
            }
        case .bankOfAmerica:
            return bankOfAmerica
        case .wellsFargo:
            return wellsFargo
        case .usBank:
            return usBank
        case .barclays:
            return barclays
        case .discover:
            return discoverIt

        // Tier 2 - Mid-Market & Specialty
        case .usaa:
            return usaa
        case .navyFederal:
            return navyFederal
        case .pnc:
            return pnc
        case .tdBank:
            return tdBank
        case .synchrony:
            return synchrony
        case .breadFinancial:
            return breadFinancial
        case .goldmanSachs:
            return goldmanSachs
        case .fnbo:
            return fnbo
        case .creditOne:
            return creditOne
        case .upgrade:
            return upgrade
        case .avant:
            return avant

        // Tier 3 - Tech/Fintech
        case .apple:
            return appleCard
        case .brex:
            return brex
        case .ramp:
            return ramp
        case .mercury:
            return mercury

        // Special
        case .custom:
            return customCard
        }
    }
}

// MARK: - Shadow Styles

struct CardShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let `default` = CardShadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    static let hover = CardShadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
    static let elevated = CardShadow(color: .black.opacity(0.25), radius: 32, x: 0, y: 12)

    #if os(macOS)
    static let defaultDark = CardShadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
    static let hoverDark = CardShadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 8)
    #endif
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Returns true if the color is considered "light" (luminance > 0.6)
    /// Used to determine if dark or light text should be displayed over this color
    var isLight: Bool {
        #if os(iOS)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor(self)
        let red = nsColor.redComponent
        let green = nsColor.greenComponent
        let blue = nsColor.blueComponent
        #endif

        // Calculate relative luminance using WCAG formula
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance > 0.6
    }
}

// MARK: - View Modifiers

struct CardShadowModifier: ViewModifier {
    let shadow: CardShadow

    func body(content: Content) -> some View {
        content.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

extension View {
    func cardShadow(_ style: CardShadow = .default) -> some View {
        modifier(CardShadowModifier(shadow: style))
    }
}

// MARK: - Hover Effect (macOS)

#if os(macOS)
struct HoverLiftEffect: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .offset(y: isHovered ? -2 : 0)
            .cardShadow(isHovered ? .hover : .default)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func hoverLift() -> some View {
        modifier(HoverLiftEffect())
    }
}
#endif

// MARK: - Multiplier Badge Style

struct MultiplierBadge: View {
    let value: Double
    var isHighValue: Bool { value >= 3.0 }

    var body: some View {
        Text(multiplierString)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(isHighValue ? Color.accentColor : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isHighValue
                    ? Color.accentColor.opacity(0.15)
                    : Color.secondary.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var multiplierString: String {
        if value == floor(value) {
            return "\(Int(value))x"
        }
        return String(format: "%.1fx", value)
    }
}

// MARK: - Status Badge

enum StatusBadgeStyle {
    case active, pending, inactive, warning, error

    var backgroundColor: Color {
        switch self {
        case .active: return .green.opacity(0.15)
        case .pending: return .orange.opacity(0.15)
        case .inactive: return .gray.opacity(0.15)
        case .warning: return .orange.opacity(0.15)
        case .error: return .red.opacity(0.15)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .active: return .green
        case .pending: return .orange
        case .inactive: return .secondary
        case .warning: return .orange
        case .error: return .red
        }
    }
}

struct StatusBadge: View {
    let text: String
    let style: StatusBadgeStyle

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(style.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
