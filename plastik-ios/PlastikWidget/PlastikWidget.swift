import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct CardEntry: TimelineEntry {
    let date: Date
    let bestCard: WidgetCard?
    let topCards: [WidgetCard]
    let bonusProgress: [WidgetBonus]
    let category: SpendCategory
}

struct WidgetCard: Identifiable {
    let id: String
    let name: String
    let issuer: String
    let multiplier: Double
    let network: String
}

struct WidgetBonus {
    let cardName: String
    let progress: Double
    let spentSoFar: Int
    let targetSpend: Int
    let daysRemaining: Int
}

// MARK: - Category Intent

struct SelectCategoryIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Category"
    static var description = IntentDescription("Choose a spending category to see the best card.")

    @Parameter(title: "Category", default: .dining)
    var category: SpendCategory
}

extension SpendCategory: AppEnum {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Spend Category")

    static var caseDisplayRepresentations: [SpendCategory: DisplayRepresentation] {
        [
            .dining: "Dining",
            .travel: "Travel",
            .groceries: "Groceries",
            .gas: "Gas",
            .streaming: "Streaming",
            .drugstores: "Drugstores",
            .homeImprovement: "Home Improvement",
            .online: "Online Shopping",
            .entertainment: "Entertainment",
            .utilities: "Utilities",
            .other: "Other"
        ]
    }
}

// MARK: - Timeline Provider

struct CardProvider: AppIntentTimelineProvider {
    typealias Entry = CardEntry
    typealias Intent = SelectCategoryIntent

    func placeholder(in context: Context) -> CardEntry {
        CardEntry(
            date: .now,
            bestCard: WidgetCard(id: "placeholder", name: "Sapphire Preferred", issuer: "Chase", multiplier: 3.0, network: "Visa"),
            topCards: [],
            bonusProgress: [],
            category: .dining
        )
    }

    func snapshot(for configuration: SelectCategoryIntent, in context: Context) async -> CardEntry {
        await fetchEntry(for: configuration.category)
    }

    func timeline(for configuration: SelectCategoryIntent, in context: Context) async -> Timeline<CardEntry> {
        let entry = await fetchEntry(for: configuration.category)
        return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600)))
    }

    private func fetchEntry(for category: SpendCategory) async -> CardEntry {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var cards: [CreditCard] = []
        var userCards: [UserCard] = []

        // Try loading card catalog from: 1) App Group, 2) Standard UserDefaults, 3) Bundle
        if let data = Constants.sharedDefaults?.data(forKey: Constants.feedCacheKey),
           let feed = try? decoder.decode(CardDataFeed.self, from: data) {
            cards = feed.cards
        } else if let data = UserDefaults.standard.data(forKey: Constants.feedCacheKey),
                  let feed = try? decoder.decode(CardDataFeed.self, from: data) {
            cards = feed.cards
        } else if let bundledURL = Bundle.main.url(forResource: "plastik-data", withExtension: "json"),
                  let data = try? Data(contentsOf: bundledURL),
                  let feed = try? decoder.decode(CardDataFeed.self, from: data) {
            cards = feed.cards
        }

        // Load user cards from: 1) App Group, 2) Standard UserDefaults
        if let data = Constants.sharedDefaults?.data(forKey: "localUserCards"),
           let decoded = try? JSONDecoder().decode([UserCard].self, from: data) {
            userCards = decoded
        } else if let data = UserDefaults.standard.data(forKey: "localUserCards"),
                  let decoded = try? JSONDecoder().decode([UserCard].self, from: data) {
            userCards = decoded
        }

        // Find best cards for category among user's cards
        let userCardIds = Set(userCards.map(\.cardId))
        let userCatalog = cards.filter { userCardIds.contains($0.id) }

        let sorted = userCatalog.sorted { a, b in
            let aRate = a.earningRates.first { $0.category == category }?.multiplier ?? 1.0
            let bRate = b.earningRates.first { $0.category == category }?.multiplier ?? 1.0
            return aRate > bRate
        }

        let best = sorted.first.map { card in
            let rate = card.earningRates.first { $0.category == category }?.multiplier ?? 1.0
            return WidgetCard(id: card.id, name: card.name, issuer: card.issuer.displayName, multiplier: rate, network: card.network.displayName)
        }

        let top3 = Array(sorted.prefix(3)).map { card in
            let rate = card.earningRates.first { $0.category == category }?.multiplier ?? 1.0
            return WidgetCard(id: card.id, name: card.name, issuer: card.issuer.displayName, multiplier: rate, network: card.network.displayName)
        }

        // Bonus progress
        let bonuses = userCards.compactMap { uc -> WidgetBonus? in
            guard let bonus = uc.signupBonusProgress, !bonus.completed, !bonus.isExpired else { return nil }
            let cardName = cards.first { $0.id == uc.cardId }?.name ?? uc.cardId
            return WidgetBonus(
                cardName: cardName,
                progress: bonus.progress,
                spentSoFar: bonus.spentSoFar,
                targetSpend: bonus.targetSpend,
                daysRemaining: bonus.daysRemaining
            )
        }

        return CardEntry(
            date: .now,
            bestCard: best,
            topCards: top3,
            bonusProgress: bonuses,
            category: category
        )
    }
}

// MARK: - Widget Definition

struct PlastikWidget: Widget {
    let kind: String = "PlastikWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCategoryIntent.self,
            provider: CardProvider()
        ) { entry in
            PlastikWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Best Card")
        .description("Shows the best card for your selected category")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular])
    }
}

@main
struct PlastikWidgetBundle: WidgetBundle {
    var body: some Widget {
        PlastikWidget()
    }
}
