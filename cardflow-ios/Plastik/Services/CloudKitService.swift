import Foundation

/// iCloud Drive file-based sync service that shares data with the Electron macOS app.
/// Both platforms read/write `cardflow-data.json` in iCloud Drive:
/// - iOS: accessed via the default ubiquity container (nil) → Documents/Plastik/
/// - macOS Electron: ~/Library/Mobile Documents/com~apple~CloudDocs/Plastik/
@Observable
class CloudKitService {
    var isSyncing = false
    var lastSyncDate: Date?
    var syncError: String?

    private let folderName = "Plastik"
    private let fileName = "cardflow-data.json"

    // MARK: - iCloud Drive File URL

    /// Returns the URL for cardflow-data.json in iCloud Drive.
    /// Using nil for the container identifier gives access to the user's default
    /// iCloud Drive (com~apple~CloudDocs on macOS, the root iCloud Drive on iOS).
    var resolvedFileURL: URL? {
        // nil = default ubiquity container = iCloud Drive root
        guard let driveURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            return nil
        }
        // On iOS, the ubiquity URL + "Documents" maps to the root of iCloud Drive
        let documentsURL = driveURL.appendingPathComponent("Documents")
        return documentsURL.appendingPathComponent(folderName).appendingPathComponent(fileName)
    }

    // MARK: - Shared Data Structure

    /// The JSON structure matching what the Electron app reads/writes
    struct SharedData: Codable {
        var schemaVersion: Int = 1
        var lastModified: String = ISO8601DateFormatter().string(from: Date())
        var lastModifiedBy: String = "ios"
        var cards: [[String: AnyCodable]]
        var pointsBalances: [String: AnyCodable]
        var companionPasses: [[String: AnyCodable]]
        var applications: [[String: AnyCodable]]
        var creditPulls: [[String: AnyCodable]]
        var holders: [String]

        init() {
            cards = []
            pointsBalances = [:]
            companionPasses = []
            applications = []
            creditPulls = []
            holders = ["Sterling", "Spouse"]
        }
    }

    // MARK: - Read / Write

    func readSharedData() -> SharedData? {
        guard let fileURL = resolvedFileURL else {
            syncError = "iCloud Drive not available"
            return nil
        }

        // Ensure the file is downloaded from iCloud
        let fm = FileManager.default
        if !fm.fileExists(atPath: fileURL.path) {
            // Try to trigger download
            do {
                try fm.startDownloadingUbiquitousItem(at: fileURL)
            } catch {
                // File may not exist yet
            }
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let shared = try decoder.decode(SharedData.self, from: data)
            lastSyncDate = Date()
            syncError = nil
            return shared
        } catch {
            syncError = "Failed to read iCloud data: \(error.localizedDescription)"
            return nil
        }
    }

    func writeSharedData(_ sharedData: SharedData) -> Bool {
        guard let fileURL = resolvedFileURL else {
            syncError = "iCloud Drive not available"
            return false
        }

        let fm = FileManager.default
        let folderURL = fileURL.deletingLastPathComponent()

        // Create the Plastik folder if needed
        if !fm.fileExists(atPath: folderURL.path) {
            do {
                try fm.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } catch {
                syncError = "Failed to create iCloud folder: \(error.localizedDescription)"
                return false
            }
        }

        do {
            var data = sharedData
            data.lastModified = ISO8601DateFormatter().string(from: Date())
            data.lastModifiedBy = "ios"
            data.schemaVersion = 1

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: fileURL, options: .atomic)
            lastSyncDate = Date()
            syncError = nil
            return true
        } catch {
            syncError = "Failed to write iCloud data: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - User Cards Conversion

    /// Convert UserCard array to the JSON format the Electron app expects
    func userCardsToSharedFormat(_ userCards: [UserCard]) -> [[String: AnyCodable]] {
        let dateFormatter = ISO8601DateFormatter()
        return userCards.map { card in
            var dict: [String: AnyCodable] = [
                "id": AnyCodable(card.id.uuidString),
                "cardId": AnyCodable(card.cardId),
                "openDate": AnyCodable(dateFormatter.string(from: card.openDate)),
                "isActive": AnyCodable(card.isActive),
                "lastModified": AnyCodable(dateFormatter.string(from: card.lastModified)),
                "isBusinessCard": AnyCodable(card.isBusinessCard),
                "wasProductChanged": AnyCodable(card.wasProductChanged)
            ]
            if let nickname = card.nickname { dict["nickname"] = AnyCodable(nickname) }
            if let lastFour = card.lastFourDigits { dict["lastFour"] = AnyCodable(lastFour) }
            if let notes = card.notes { dict["notes"] = AnyCodable(notes) }
            if let annualFeeDate = card.annualFeeDate { dict["annualFeeDate"] = AnyCodable(dateFormatter.string(from: annualFeeDate)) }
            if let closedDate = card.closedDate { dict["closedDate"] = AnyCodable(dateFormatter.string(from: closedDate)) }
            if let bonusReceivedDate = card.signupBonusReceivedDate { dict["signupBonusReceivedDate"] = AnyCodable(dateFormatter.string(from: bonusReceivedDate)) }
            if let productFamily = card.productFamily { dict["productFamily"] = AnyCodable(productFamily) }
            if let productChangedFrom = card.productChangedFrom { dict["productChangedFrom"] = AnyCodable(productChangedFrom) }
            if let bonus = card.signupBonusProgress {
                dict["bonusSpent"] = AnyCodable(bonus.spentSoFar)
                dict["bonusTarget"] = AnyCodable(bonus.targetSpend)
                dict["bonusDeadline"] = AnyCodable(dateFormatter.string(from: bonus.deadline))
                dict["bonusCompleted"] = AnyCodable(bonus.completed)
            }
            return dict
        }
    }

    /// Convert shared JSON format back to UserCard array
    func sharedFormatToUserCards(_ dicts: [[String: AnyCodable]]) -> [UserCard] {
        let dateFormatter = ISO8601DateFormatter()
        return dicts.compactMap { dict in
            guard let cardId = dict["cardId"]?.value as? String else { return nil }

            let id: UUID
            if let idStr = dict["id"]?.value as? String, let parsed = UUID(uuidString: idStr) {
                id = parsed
            } else {
                id = UUID()
            }

            let openDate: Date
            if let dateStr = dict["openDate"]?.value as? String, let parsed = dateFormatter.date(from: dateStr) {
                openDate = parsed
            } else {
                openDate = Date()
            }

            let lastModified: Date
            if let dateStr = dict["lastModified"]?.value as? String, let parsed = dateFormatter.date(from: dateStr) {
                lastModified = parsed
            } else {
                lastModified = Date()
            }

            let isActive = dict["isActive"]?.value as? Bool ?? true

            var bonusProgress: BonusProgress?
            if let spent = dict["bonusSpent"]?.value as? Int,
               let target = dict["bonusTarget"]?.value as? Int,
               let deadlineStr = dict["bonusDeadline"]?.value as? String,
               let deadline = dateFormatter.date(from: deadlineStr) {
                let completed = dict["bonusCompleted"]?.value as? Bool ?? (spent >= target)
                bonusProgress = BonusProgress(spentSoFar: spent, targetSpend: target, deadline: deadline, completed: completed)
            }

            var annualFeeDate: Date?
            if let dateStr = dict["annualFeeDate"]?.value as? String {
                annualFeeDate = dateFormatter.date(from: dateStr)
            }

            var closedDate: Date?
            if let dateStr = dict["closedDate"]?.value as? String {
                closedDate = dateFormatter.date(from: dateStr)
            }

            var signupBonusReceivedDate: Date?
            if let dateStr = dict["signupBonusReceivedDate"]?.value as? String {
                signupBonusReceivedDate = dateFormatter.date(from: dateStr)
            }

            return UserCard(
                id: id,
                cardId: cardId,
                nickname: dict["nickname"]?.value as? String,
                lastFourDigits: dict["lastFour"]?.value as? String,
                openDate: openDate,
                annualFeeDate: annualFeeDate,
                signupBonusProgress: bonusProgress,
                benefitUsage: [],
                isActive: isActive,
                notes: dict["notes"]?.value as? String,
                closedDate: closedDate,
                signupBonusReceivedDate: signupBonusReceivedDate,
                productFamily: dict["productFamily"]?.value as? String,
                isBusinessCard: dict["isBusinessCard"]?.value as? Bool ?? false,
                wasProductChanged: dict["wasProductChanged"]?.value as? Bool ?? false,
                productChangedFrom: dict["productChangedFrom"]?.value as? String,
                ckRecordID: nil,
                lastModified: lastModified
            )
        }
    }

    // MARK: - Fetch & Save (API matching old CloudKit interface)

    func fetchUserCards() async throws -> [UserCard] {
        isSyncing = true
        defer { isSyncing = false }

        guard let sharedData = readSharedData() else {
            return []
        }

        lastSyncDate = Date()
        syncError = nil
        return sharedFormatToUserCards(sharedData.cards)
    }

    func saveUserCard(_ card: UserCard) async throws {
        isSyncing = true
        defer { isSyncing = false }

        var sharedData = readSharedData() ?? SharedData()
        var cards = sharedFormatToUserCards(sharedData.cards)

        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index] = card
        } else {
            cards.append(card)
        }

        sharedData.cards = userCardsToSharedFormat(cards)
        _ = writeSharedData(sharedData)
    }

    func deleteUserCard(_ card: UserCard) async throws {
        var sharedData = readSharedData() ?? SharedData()
        var cards = sharedFormatToUserCards(sharedData.cards)
        cards.removeAll { $0.id == card.id }
        sharedData.cards = userCardsToSharedFormat(cards)
        _ = writeSharedData(sharedData)
    }

    // MARK: - Conflict Resolution

    func resolveConflict(local: UserCard, server: UserCard) -> UserCard {
        if local.lastModified > server.lastModified {
            return local
        }
        return server
    }

    // MARK: - iCloud Availability

    var isAvailable: Bool {
        resolvedFileURL != nil
    }
}

// MARK: - AnyCodable helper for flexible JSON encoding/decoding

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if value is NSNull {
            try container.encodeNil()
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
