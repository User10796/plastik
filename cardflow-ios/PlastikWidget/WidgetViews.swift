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
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Best Card for Category)

struct SmallWidgetView: View {
    let entry: CardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: entry.category.icon)
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(entry.category.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let card = entry.bestCard {
                Text(card.name)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer()

                HStack {
                    Text(card.multiplier.multiplierString)
                        .font(.title.bold())
                        .foregroundStyle(.blue)
                    Spacer()
                    Text(card.issuer)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No cards")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Add cards in Plastik")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget (Top 3 Cards)

struct MediumWidgetView: View {
    let entry: CardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.category.icon)
                    .foregroundStyle(.blue)
                Text("Top Cards for \(entry.category.displayName)")
                    .font(.caption.bold())
                Spacer()
            }

            if entry.topCards.isEmpty {
                Text("Add cards in Plastik to see recommendations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(entry.topCards.enumerated()), id: \.element.id) { index, card in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text(card.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(card.multiplier.multiplierString)
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget (Dashboard)

struct LargeWidgetView: View {
    let entry: CardEntry

    private let dashboardCategories: [SpendCategory] = [.dining, .travel, .groceries, .gas]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Plastik")
                .font(.headline.bold())

            // Top cards section
            VStack(alignment: .leading, spacing: 6) {
                Text("Best Cards")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                if !entry.topCards.isEmpty {
                    ForEach(entry.topCards.prefix(3)) { card in
                        HStack {
                            Image(systemName: entry.category.icon)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .frame(width: 16)
                            Text(card.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(card.multiplier.multiplierString)
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                        }
                    }
                } else {
                    Text("Add cards to see recommendations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Bonus progress section
            VStack(alignment: .leading, spacing: 6) {
                Text("Bonus Progress")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                if entry.bonusProgress.isEmpty {
                    Text("No active bonuses")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(Array(entry.bonusProgress.prefix(3).enumerated()), id: \.offset) { _, bonus in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(bonus.cardName)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(bonus.daysRemaining)d left")
                                    .font(.caption2)
                                    .foregroundStyle(bonus.daysRemaining < 30 ? .red : .secondary)
                            }
                            ProgressView(value: bonus.progress)
                                .tint(.blue)
                            HStack {
                                Text("$\(bonus.spentSoFar.formatted())")
                                    .font(.caption2)
                                Spacer()
                                Text("$\(bonus.targetSpend.formatted())")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Lock Screen Circular Widget

struct CircularWidgetView: View {
    let entry: CardEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: entry.category.icon)
                    .font(.caption)
                if let card = entry.bestCard {
                    Text(card.multiplier.multiplierString)
                        .font(.caption2.bold())
                } else {
                    Text("--")
                        .font(.caption2)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
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
