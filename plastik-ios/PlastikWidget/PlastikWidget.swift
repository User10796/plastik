import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct CardEntry: TimelineEntry {
    let date: Date
    let categoryCards: [CategoryCard]  // Best card for each category
    let bonusProgress: [WidgetBonus]
}

struct CategoryCard: Identifiable {
    let id: String
    let category: SpendCategory
    let cardName: String
    let issuer: String
    let multiplier: Double
    let nickname: String?       // User-assigned nickname
    let cardIconColor: String?  // User-chosen icon hex color

    /// Display name: prefer nickname, then full card name
    var displayName: String {
        nickname ?? cardName
    }
}

struct WidgetBonus {
    let cardName: String
    let progress: Double
    let spentSoFar: Int
    let targetSpend: Int
    let daysRemaining: Int
}

// MARK: - Timeline Provider

struct CardProvider: TimelineProvider {
    typealias Entry = CardEntry

    func placeholder(in context: Context) -> CardEntry {
        CardEntry(
            date: .now,
            categoryCards: [
                CategoryCard(id: "1", category: .dining, cardName: "Sapphire Preferred", issuer: "Chase", multiplier: 3.0, nickname: nil, cardIconColor: nil),
                CategoryCard(id: "2", category: .groceries, cardName: "Gold Card", issuer: "Amex", multiplier: 4.0, nickname: nil, cardIconColor: nil),
                CategoryCard(id: "3", category: .gas, cardName: "Freedom Flex", issuer: "Chase", multiplier: 3.0, nickname: nil, cardIconColor: nil)
            ],
            bonusProgress: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CardEntry) -> Void) {
        let entry = fetchEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CardEntry>) -> Void) {
        let entry = fetchEntry()
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600)))
        completion(timeline)
    }

    private func fetchEntry() -> CardEntry {
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

        // Load user cards from: 1) Shared file, 2) App Group defaults, 3) Standard defaults
        if let containerURL = Constants.appGroupContainerURL {
            let fileURL = containerURL.appendingPathComponent("userCards.json")
            if let data = try? Data(contentsOf: fileURL),
               let decoded = try? JSONDecoder().decode([UserCard].self, from: data) {
                userCards = decoded
                let colorsSet = decoded.filter { $0.cardIconColor != nil }.count
                print("Widget: Loaded \(decoded.count) cards from shared FILE (\(colorsSet) with custom colors)")
            } else {
                print("Widget: Shared file not found or unreadable at \(fileURL.path)")
            }
        }

        // Fallback to UserDefaults if file didn't work
        if userCards.isEmpty {
            if let shared = Constants.sharedDefaults,
               let data = shared.data(forKey: "localUserCards"),
               let decoded = try? JSONDecoder().decode([UserCard].self, from: data) {
                userCards = decoded
                let colorsSet = decoded.filter { $0.cardIconColor != nil }.count
                print("Widget: Loaded \(decoded.count) cards from shared DEFAULTS (\(colorsSet) with custom colors)")
            } else if let data = UserDefaults.standard.data(forKey: "localUserCards"),
                      let decoded = try? JSONDecoder().decode([UserCard].self, from: data) {
                userCards = decoded
                print("Widget: Loaded \(decoded.count) cards from STANDARD defaults (shared unavailable)")
            } else {
                print("Widget: No user cards found in any source")
            }
        }

        // Filter to only user's active cards
        let activeUserCards = userCards.filter { $0.closedDate == nil }
        let activeUserCardIds = Set(activeUserCards.map(\.cardId))
        let userCatalog = cards.filter { activeUserCardIds.contains($0.id) }

        // Build a lookup of user cards by cardId for override checks
        let userCardsByCardId: [String: UserCard] = Dictionary(
            activeUserCards.map { ($0.cardId, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // Find best card for each category
        let categories: [SpendCategory] = [.dining, .groceries, .gas, .travel, .streaming, .online]
        var categoryCards: [CategoryCard] = []

        for category in categories {
            // Find card with highest multiplier for this category
            // Check user overrides first, then fall back to catalog
            let bestCard = userCatalog
                .compactMap { card -> (CreditCard, Double)? in
                    let userCard = userCardsByCardId[card.id]

                    // Check user-overridden reward categories first
                    if let overrides = userCard?.rewardCategoriesOverride,
                       let override = overrides.first(where: {
                           $0.categoryName.lowercased() == category.displayName.lowercased()
                       }) {
                        return (card, override.rewardRate)
                    }

                    // Fall back to catalog earning rates
                    guard let rate = card.earningRates.first(where: { $0.category == category }) else {
                        return nil
                    }
                    return (card, rate.multiplier)
                }
                .sorted { $0.1 > $1.1 }
                .first

            if let (card, multiplier) = bestCard, multiplier > 1.0 {
                let userCard = userCardsByCardId[card.id]
                categoryCards.append(CategoryCard(
                    id: "\(category.rawValue)-\(card.id)",
                    category: category,
                    cardName: card.name,
                    issuer: card.issuer.displayName,
                    multiplier: multiplier,
                    nickname: userCard?.nickname,
                    cardIconColor: userCard?.cardIconColor
                ))
            }
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

        // Diagnostic: Log what widget is showing
        for cc in categoryCards {
            print("Widget entry: \(cc.category.displayName) -> \(cc.cardName), color: \(cc.cardIconColor ?? "default")")
        }

        return CardEntry(
            date: .now,
            categoryCards: categoryCards,
            bonusProgress: bonuses
        )
    }
}

// MARK: - Widget Definition

struct PlastikWidget: Widget {
    let kind: String = "PlastikWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: CardProvider()
        ) { entry in
            PlastikWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Best Cards")
        .description("Shows the best card for each spending category")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular])
        .contentMarginsDisabled()  // Remove system margins for more space
    }
}

@main
struct PlastikWidgetBundle: WidgetBundle {
    var body: some Widget {
        PlastikWidget()
    }
}
