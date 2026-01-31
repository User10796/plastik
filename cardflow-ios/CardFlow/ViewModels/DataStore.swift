import Foundation
import SwiftUI

@Observable
class DataStore {
    var cards: [CreditCard] = []
    var pointsBalances: [String: Double] = [:]
    var companionPasses: [CompanionPass] = []
    var applications: [CardApplication] = []
    var creditPulls: [CreditPull] = []
    var holders: [String] = []
    var apiKey: String = ""
    var isLoading = true
    var iCloudAvailable = false
    var lastSyncDate: Date?

    private var cloudManager: CloudDataManager?
    private var saveDebounceTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var totalBalance: Double {
        cards.reduce(0) { $0 + $1.currentBalance }
    }

    var totalAnnualFees: Double {
        cards.reduce(0) { $0 + $1.annualFee }
    }

    var fiveOverTwentyFour: Int {
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"
        return cards.filter { card in
            guard let openDate = isoFormatter.date(from: card.openDate) else { return false }
            return openDate > twoYearsAgo
        }.count
    }

    var canApplyChase: Bool {
        fiveOverTwentyFour < 5
    }

    var cardsWithBalance: [CreditCard] {
        cards.filter { $0.currentBalance > 0 }.sorted { $0.currentBalance < $1.currentBalance }
    }

    var upcomingAnniversaries: [CreditCard] {
        cards
            .filter { $0.annualFee > 0 }
            .sorted { (Formatters.daysUntil($0.anniversaryDate) ?? 999) < (Formatters.daysUntil($1.anniversaryDate) ?? 999) }
    }

    // MARK: - Init & Load

    init() {
        cloudManager = CloudDataManager()
        cloudManager?.onDataChanged = { [weak self] data in
            DispatchQueue.main.async {
                self?.applyCloudData(data)
            }
        }
    }

    func load() {
        isLoading = true

        // Load API key from Keychain
        apiKey = KeychainService.load(key: "anthropic-api-key") ?? ""

        // Try loading from iCloud first
        if let cloudData = cloudManager?.load() {
            applyCloudData(cloudData)
            iCloudAvailable = cloudManager?.isAvailable ?? false
            lastSyncDate = Date()
        }

        // If no data loaded, use empty defaults
        if cards.isEmpty && holders.isEmpty {
            holders = ["Person 1"]
        }

        isLoading = false
    }

    private func applyCloudData(_ data: CardFlowData) {
        cards = data.cards
        pointsBalances = data.pointsBalances
        companionPasses = data.companionPasses
        applications = data.applications
        creditPulls = data.creditPulls
        if !data.holders.isEmpty {
            holders = data.holders
        }
        lastSyncDate = Date()
    }

    // MARK: - Save

    func save() {
        saveDebounceTask?.cancel()
        saveDebounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second debounce
            guard !Task.isCancelled else { return }
            self.performSave()
        }
    }

    private func performSave() {
        guard !isLoading else { return }
        var data = CardFlowData()
        data.cards = cards
        data.pointsBalances = pointsBalances
        data.companionPasses = companionPasses
        data.applications = applications
        data.creditPulls = creditPulls
        data.holders = holders
        data.lastModified = ISO8601DateFormatter().string(from: Date())
        data.lastModifiedBy = "ios"
        cloudManager?.save(data)
        lastSyncDate = Date()
    }

    func saveApiKey(_ key: String) {
        apiKey = key
        _ = KeychainService.save(key: "anthropic-api-key", value: key)
    }

    func syncNow() {
        performSave()
    }

    // MARK: - Card Operations

    func addCard(_ card: CreditCard) {
        cards.append(card)
        save()
    }

    func updateCard(_ card: CreditCard) {
        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx] = card
            save()
        }
    }

    func deleteCard(_ card: CreditCard) {
        cards.removeAll { $0.id == card.id }
        save()
    }

    // MARK: - Application Operations

    func addApplication(_ app: CardApplication) {
        applications.append(app)
        save()
    }

    func updateApplication(_ app: CardApplication) {
        if let idx = applications.firstIndex(where: { $0.id == app.id }) {
            applications[idx] = app
            save()
        }
    }

    func deleteApplication(_ app: CardApplication) {
        applications.removeAll { $0.id == app.id }
        save()
    }

    // MARK: - Points Operations

    func updatePoints(type: String, balance: Double) {
        pointsBalances[type] = balance
        save()
    }

    // MARK: - Companion Pass Operations

    func addCompanionPass(_ pass: CompanionPass) {
        companionPasses.append(pass)
        save()
    }

    func updateCompanionPass(at index: Int, _ pass: CompanionPass) {
        guard index >= 0 && index < companionPasses.count else { return }
        companionPasses[index] = pass
        save()
    }

    func deleteCompanionPass(at index: Int) {
        guard index >= 0 && index < companionPasses.count else { return }
        companionPasses.remove(at: index)
        save()
    }

    // MARK: - Credit Pull Operations

    func addCreditPulls(_ pulls: [CreditPull]) {
        // Deduplicate
        for pull in pulls {
            let exists = creditPulls.contains { $0.bureau == pull.bureau && $0.creditor == pull.creditor && $0.date == pull.date }
            if !exists {
                creditPulls.append(pull)
            }
        }
        save()
    }

    func deleteCreditPull(_ pull: CreditPull) {
        creditPulls.removeAll { $0.id == pull.id }
        save()
    }

    // MARK: - Holder Operations

    func addHolder(_ name: String) {
        guard !name.isEmpty && !holders.contains(name) else { return }
        holders.append(name)
        save()
    }

    func removeHolder(_ name: String) {
        guard holders.count > 1 else { return }
        holders.removeAll { $0 == name }
        save()
    }
}
