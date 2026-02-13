import Foundation
import WidgetKit

struct CardDataFeed: Codable {
    let version: String
    let lastUpdated: Date
    let cards: [CreditCard]
    let offers: [CardOffer]
    let transferPartners: [TransferPartner]
    let churnRules: [ChurnRule]
    let transferRoutes: [TransferRoute]?
    let pointsCurrencies: [PointsCurrency]?
    let downgradePaths: [DowngradePath]?
    let historicalBonuses: [HistoricalBonus]?
}

enum DataFeedError: LocalizedError {
    case networkError
    case decodingError(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .networkError: return "Failed to fetch card data from network."
        case .decodingError(let msg): return "Failed to decode card data: \(msg)"
        case .noData: return "No card data available."
        }
    }
}

@Observable
class DataFeedService {
    var cards: [CreditCard] = []
    var offers: [CardOffer] = []
    var transferPartners: [TransferPartner] = []
    var churnRules: [ChurnRule] = []
    var transferRoutes: [TransferRoute] = []
    var pointsCurrencies: [PointsCurrency] = []
    var downgradePaths: [DowngradePath] = []
    var historicalBonuses: [HistoricalBonus] = []
    var lastUpdated: Date?
    var isLoading = false
    var error: DataFeedError?

    private let feedURL: URL = {
        guard let url = URL(string: Constants.feedURL) else {
            fatalError("Invalid feed URL in Constants — this is a programmer error")
        }
        return url
    }()

    // Shared App Group for widget access
    private var sharedDefaults: UserDefaults? {
        Constants.sharedDefaults
    }

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func loadData() {
        loadCachedOrBundled()
        // Trigger widget refresh when data is loaded
        WidgetCenter.shared.reloadAllTimelines()
        Task {
            try? await fetchLatestData()
        }
    }

    func fetchLatestData() async throws {
        await MainActor.run { self.isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }

        let (data, response) = try await URLSession.shared.data(from: feedURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DataFeedError.networkError
        }

        let feed: CardDataFeed
        do {
            feed = try decoder.decode(CardDataFeed.self, from: data)
        } catch {
            throw DataFeedError.decodingError(error.localizedDescription)
        }

        // Only apply remote data if it has MORE cards than current data
        // This prevents remote URL from overwriting richer bundled data
        let currentCardCount = await MainActor.run { self.cards.count }
        if feed.cards.count >= currentCardCount {
            // Save to both standard and shared defaults for widget access
            UserDefaults.standard.set(data, forKey: Constants.feedCacheKey)
            sharedDefaults?.set(data, forKey: Constants.feedCacheKey)

            await MainActor.run {
                applyFeed(feed)
                print("🌐 Applied remote feed: \(feed.cards.count) cards (v\(feed.version))")
            }

            // Trigger widget refresh
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            print("⏭️ Skipped remote feed (\(feed.cards.count) cards) - current data has more (\(currentCardCount) cards)")
        }
    }

    func loadCachedOrBundled() {
        // Always load from bundled JSON first (ensures latest data during development)
        if let bundledURL = Bundle.main.url(forResource: "plastik-data", withExtension: "json"),
           let data = try? Data(contentsOf: bundledURL) {
            do {
                let feed = try decoder.decode(CardDataFeed.self, from: data)
                applyFeed(feed)
                // Update caches
                UserDefaults.standard.set(data, forKey: Constants.feedCacheKey)
                sharedDefaults?.set(data, forKey: Constants.feedCacheKey)
                print("✅ Loaded \(feed.cards.count) cards from bundled JSON (v\(feed.version))")
                return
            } catch {
                print("❌ Failed to decode bundled JSON: \(error)")
            }
        }

        // Fallback to cached data if bundled fails
        if let cachedData = UserDefaults.standard.data(forKey: Constants.feedCacheKey),
           let feed = try? decoder.decode(CardDataFeed.self, from: cachedData) {
            applyFeed(feed)
            print("📦 Loaded \(feed.cards.count) cards from cache")
        }
    }

    private func applyFeed(_ feed: CardDataFeed) {
        self.cards = feed.cards
        self.offers = feed.offers
        self.transferPartners = feed.transferPartners
        self.churnRules = feed.churnRules
        self.transferRoutes = feed.transferRoutes ?? []
        self.pointsCurrencies = feed.pointsCurrencies ?? []
        self.downgradePaths = feed.downgradePaths ?? []
        self.historicalBonuses = feed.historicalBonuses ?? []
        self.lastUpdated = feed.lastUpdated
        self.error = nil
    }

    // MARK: - Lookups

    func card(for id: String) -> CreditCard? {
        cards.first { $0.id == id }
    }

    func bestCard(for category: SpendCategory) -> CreditCard? {
        cards.max { a, b in
            let aRate = a.earningRates.first { $0.category == category }?.multiplier ?? 1.0
            let bRate = b.earningRates.first { $0.category == category }?.multiplier ?? 1.0
            return aRate < bRate
        }
    }

    func partners(for card: CreditCard) -> [TransferPartner] {
        transferPartners.filter { card.transferPartners.contains($0.id) }
    }

    func rules(for card: CreditCard) -> [ChurnRule] {
        churnRules.filter { card.churnRules.issuerRules.contains($0.id) }
    }

    func routes(for currencyId: String) -> [TransferRoute] {
        transferRoutes.filter { $0.fromCurrency == currencyId }
    }

    func routes(to partnerId: String) -> [TransferRoute] {
        transferRoutes.filter { $0.toPartner == partnerId }
    }

    func currency(for id: String) -> PointsCurrency? {
        pointsCurrencies.first { $0.id == id }
    }

    func downgradePaths(for cardId: String) -> DowngradePath? {
        downgradePaths.first { $0.fromCard == cardId }
    }

    func historicalBonus(for cardId: String) -> HistoricalBonus? {
        historicalBonuses.first { $0.cardId == cardId }
    }

    func userCurrencies(for userCards: [UserCard]) -> [PointsCurrency] {
        pointsCurrencies.filter { currency in
            userCards.contains { uc in currency.earnedWith.contains(uc.cardId) }
        }
    }
}
