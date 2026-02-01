import Foundation

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
    private let cacheKey = "cachedCardData"

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func loadData() {
        loadCachedOrBundled()
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

        UserDefaults.standard.set(data, forKey: cacheKey)
        applyFeed(feed)
    }

    func loadCachedOrBundled() {
        if let cached = UserDefaults.standard.data(forKey: cacheKey),
           let feed = try? decoder.decode(CardDataFeed.self, from: cached) {
            applyFeed(feed)
        } else if let bundledURL = Bundle.main.url(forResource: "plastik-data", withExtension: "json"),
                  let data = try? Data(contentsOf: bundledURL),
                  let feed = try? decoder.decode(CardDataFeed.self, from: data) {
            applyFeed(feed)
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
