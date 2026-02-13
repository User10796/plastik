import SwiftUI
import WidgetKit

// MARK: - Main Entry View

struct PlastikWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: CardEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryCircular:
            CircularWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Top 2 Categories with Mini Cards)

struct SmallWidgetView: View {
    let entry: CardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text("Best Cards")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.secondary)

            if entry.categoryCards.isEmpty {
                Spacer()
                Text("Add cards in Plastik")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                VStack(spacing: 8) {
                    ForEach(entry.categoryCards.prefix(2)) { item in
                        SmallCategoryRow(item: item)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(8)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SmallCategoryRow: View {
    let item: CategoryCard

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Category name
            HStack(spacing: 3) {
                Image(systemName: item.category.icon)
                    .font(.system(size: 9))
                    .foregroundStyle(.blue)
                Text(item.category.displayName)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            // Card with mini icon
            HStack(spacing: 4) {
                WidgetMiniCard(issuer: item.issuer, customColor: item.cardIconColor, size: 20)

                Text(item.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                Text(item.multiplier.multiplierString)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
            }
        }
    }
}

// MARK: - Medium Widget (Vertical Category List)

struct MediumWidgetView: View {
    let entry: CardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
                Text("Which card should I use?")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if entry.categoryCards.isEmpty {
                Text("Add cards in Plastik to see recommendations")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(spacing: 0) {
                    ForEach(entry.categoryCards.prefix(5)) { item in
                        MediumCategoryRow(item: item)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumCategoryRow: View {
    let item: CategoryCard

    var body: some View {
        HStack(spacing: 6) {
            // Category icon
            Image(systemName: item.category.icon)
                .font(.system(size: 12))
                .foregroundStyle(.blue)
                .frame(width: 14)

            // Category name
            Text(item.category.shortName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)

            // Mini card icon - uses custom color if set
            WidgetMiniCard(issuer: item.issuer, customColor: item.cardIconColor, size: 22)

            // Card name - full nickname or card name
            Text(item.displayName)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 4)

            // Multiplier
            Text(item.multiplier.multiplierString)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(item.multiplier >= 3 ? .blue : .primary)
        }
        .frame(height: 24)
    }
}

// MARK: - Large Widget (Full Dashboard with Mini Cards)

struct LargeWidgetView: View {
    let entry: CardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Plastik")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text("\(entry.categoryCards.count) categories")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Best cards by category
            VStack(alignment: .leading, spacing: 6) {
                Text("Best Cards")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                if entry.categoryCards.isEmpty {
                    Text("Add cards to see recommendations")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(entry.categoryCards.prefix(5)) { item in
                        LargeCategoryRow(item: item)
                    }
                }
            }

            Divider()

            // Bonus progress section
            VStack(alignment: .leading, spacing: 6) {
                Text("Bonus Progress")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                if entry.bonusProgress.isEmpty {
                    Text("No active bonuses")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(Array(entry.bonusProgress.prefix(2).enumerated()), id: \.offset) { _, bonus in
                        BonusProgressRow(bonus: bonus)
                    }
                }
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeCategoryRow: View {
    let item: CategoryCard

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: item.category.icon)
                .font(.system(size: 11))
                .foregroundStyle(.blue)
                .frame(width: 14)

            Text(item.category.displayName)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            WidgetMiniCard(issuer: item.issuer, customColor: item.cardIconColor, size: 20)

            Text(item.displayName)
                .font(.system(size: 11))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            Text(item.multiplier.multiplierString)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
        }
    }
}

struct BonusProgressRow: View {
    let bonus: WidgetBonus

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(bonus.cardName)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Text("\(bonus.daysRemaining)d")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(bonus.daysRemaining < 30 ? .red : .secondary)
            }

            ProgressView(value: bonus.progress)
                .tint(.blue)
                .scaleEffect(y: 0.8)

            HStack {
                Text("$\(bonus.spentSoFar.formatted())")
                    .font(.system(size: 9))
                Spacer()
                Text("$\(bonus.targetSpend.formatted())")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Lock Screen Widgets

struct CircularWidgetView: View {
    let entry: CardEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 14))
                Text("\(entry.categoryCards.count)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct RectangularWidgetView: View {
    let entry: CardEntry

    var body: some View {
        if let first = entry.categoryCards.first {
            HStack(spacing: 6) {
                WidgetMiniCard(issuer: first.issuer, customColor: first.cardIconColor, size: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text(first.category.displayName)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text(first.displayName)
                            .font(.system(size: 12, weight: .medium))
                        Text(first.multiplier.multiplierString)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.blue)
                    }
                }
                Spacer()
            }
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            Text("Add cards in Plastik")
                .font(.system(size: 12))
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

// MARK: - Mini Card Icon for Widget

struct WidgetMiniCard: View {
    let issuer: String
    var customColor: String? = nil  // User-chosen hex color override
    var size: CGFloat = 24

    private var gradient: LinearGradient {
        // Use custom color if provided
        if let hex = customColor, !hex.isEmpty {
            let baseColor = Color(hex: hex)
            let darkerColor = Color(hex: hex).opacity(0.7)
            return LinearGradient(colors: [baseColor, darkerColor], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        let colors: [Color]
        let issuerLower = issuer.lowercased()

        if issuerLower.contains("chase") {
            colors = [Color(hex: "004879"), Color(hex: "1a6bb3")]
        } else if issuerLower.contains("amex") || issuerLower.contains("american express") {
            colors = [Color(hex: "006FCF"), Color(hex: "00A1E4")]
        } else if issuerLower.contains("capital one") {
            colors = [Color(hex: "D03027"), Color(hex: "a02620")]
        } else if issuerLower.contains("citi") {
            colors = [Color(hex: "003B70"), Color(hex: "0066b2")]
        } else if issuerLower.contains("discover") {
            colors = [Color(hex: "FF6600"), Color(hex: "ff8533")]
        } else if issuerLower.contains("bank of america") || issuerLower.contains("bofa") {
            colors = [Color(hex: "E31837"), Color(hex: "a31228")]
        } else if issuerLower.contains("wells fargo") {
            colors = [Color(hex: "CD1409"), Color(hex: "9a0f07")]
        } else if issuerLower.contains("barclays") {
            colors = [Color(hex: "00AEEF"), Color(hex: "0088cc")]
        } else {
            colors = [Color(hex: "4a5568"), Color(hex: "2d3748")]
        }

        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.15)
            .fill(gradient)
            .frame(width: size, height: size * 0.625) // 16:10 ratio
            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Helpers

extension Double {
    var multiplierString: String {
        if self == floor(self) {
            return "\(Int(self))x"
        }
        return String(format: "%.1fx", self)
    }
}

extension SpendCategory {
    var shortName: String {
        switch self {
        case .dining: return "Dining"
        case .travel: return "Travel"
        case .groceries: return "Grocery"
        case .gas: return "Gas"
        case .streaming: return "Stream"
        case .drugstores: return "Drug"
        case .homeImprovement: return "Home"
        case .online: return "Online"
        case .entertainment: return "Fun"
        case .utilities: return "Util"
        case .other: return "Other"
        }
    }
}

// cardShortName removed - widget now shows full nickname or card name via displayName

// Color extension for widget
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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
}
